"""
media_reader.py — Windows Media Control API + обложка через Deezer API.
Deezer бесплатный, без ключей, обложки до 1000x1000.
"""
import ssl
import certifi
import asyncio
import threading
import time
import urllib.request
import urllib.parse
import urllib.error
import json as _json
from dataclasses import dataclass
from typing import Optional

from winsdk.windows.media.control import (
    GlobalSystemMediaTransportControlsSessionManager as MediaManager,
    GlobalSystemMediaTransportControlsSessionPlaybackStatus as PlaybackStatus,
)
from winsdk.windows.storage.streams import DataReader, Buffer, InputStreamOptions


@dataclass
class TrackInfo:
    title: str = ""
    artist: str = ""
    album: str = ""
    duration_ms: int = 0
    position_ms: int = 0
    is_playing: bool = False
    cover_bytes: Optional[bytes] = None


# ── Постоянный ProactorEventLoop ──────────────────────────────────────────────
_loop: Optional[asyncio.AbstractEventLoop] = None
_loop_thread: Optional[threading.Thread] = None


def _start_loop():
    global _loop
    _loop = asyncio.ProactorEventLoop()
    asyncio.set_event_loop(_loop)
    _loop.run_forever()


def _ensure_loop():
    global _loop_thread
    if _loop is None or not _loop.is_running():
        _loop_thread = threading.Thread(target=_start_loop, daemon=True)
        _loop_thread.start()
        while _loop is None or not _loop.is_running():
            time.sleep(0.01)


async def _stream_to_bytes(stream) -> bytes:
    size = stream.size
    if not size:
        return b""
    buf = Buffer(int(size))
    await stream.read_async(buf, int(size), InputStreamOptions.READ_AHEAD)
    reader = DataReader.from_buffer(buf)
    return bytes(reader.read_bytes(int(size)))


async def _get_track() -> Optional[TrackInfo]:
    try:
        manager = await MediaManager.request_async()
        session = manager.get_current_session()
        if session is None:
            return None

        playback = session.get_playback_info()
        is_playing = (
            playback is not None
            and playback.playback_status == PlaybackStatus.PLAYING
        )

        props = await session.try_get_media_properties_async()
        if not props:
            return None

        title  = props.title or ""
        artist = props.artist or ""
        album  = props.album_title or ""

        duration_ms = position_ms = 0
        tl = session.get_timeline_properties()
        if tl:
            try:
                duration_ms = int(tl.end_time.total_seconds() * 1000)
                position_ms = int(tl.position.total_seconds()  * 1000)
            except AttributeError:
                try:
                    duration_ms = int(tl.end_time) // 10_000
                    position_ms = int(tl.position)  // 10_000
                except Exception:
                    pass

        cover_bytes: Optional[bytes] = None
        try:
            thumb = props.thumbnail
            if thumb:
                stream = await thumb.open_read_async()
                data = await _stream_to_bytes(stream)
                if len(data) > 200:
                    cover_bytes = data
        except Exception:
            pass

        return TrackInfo(
            title=title, artist=artist, album=album,
            duration_ms=duration_ms, position_ms=position_ms,
            is_playing=is_playing, cover_bytes=cover_bytes,
        )
    except Exception:
        return None


def get_track_info_sync() -> Optional[TrackInfo]:
    try:
        _ensure_loop()
        future = asyncio.run_coroutine_threadsafe(_get_track(), _loop)
        return future.result(timeout=2.0)
    except Exception:
        return None


# ── HTTP утилита ──────────────────────────────────────────────────────────────
def _http_get(url: str, timeout: int = 5, headers: dict = None) -> bytes:
    h = {"User-Agent": "Mozilla/5.0"}
    if headers:
        h.update(headers)

    req = urllib.request.Request(url, headers=h)

    # <<< ВАЖНО: используем certifi сертификаты >>>
    context = ssl.create_default_context(cafile=certifi.where())

    with urllib.request.urlopen(req, timeout=timeout, context=context) as r:
        return r.read()



# ── Обложка через Deezer API ──────────────────────────────────────────────────
_cover_cache: dict = {}   # (artist, title, album) → bytes | None


def _deezer_search_cover(artist: str, title: str, album: str = "") -> Optional[str]:
    """
    Ищет трек в Deezer и возвращает URL обложки 1000x1000.
    Без ключей, полностью бесплатно.
    """
    # Стратегии — от точной к широкой
    queries = []
    if album:
        # Самый точный: artist + track + album
        queries.append(f'artist:"{artist}" track:"{title}" album:"{album}"')
        queries.append(f'artist:"{artist}" album:"{album}"')
    queries.append(f'artist:"{artist}" track:"{title}"')
    queries.append(f"{artist} {title}")
    queries.append(f"{title} {artist}")

    for q in queries:
        try:
            url = "https://api.deezer.com/search?" + urllib.parse.urlencode({
                "q": q,
                "limit": "1",
            })
            resp = _http_get(url, timeout=6)
            data = _json.loads(resp)

            items = data.get("data", [])
            if not items:
                continue

            track = items[0]

            # Пробуем album → cover_xl (1000x1000), потом cover_big (500x500)
            alb = track.get("album", {})
            cover_url = alb.get("cover_xl") or alb.get("cover_big") or alb.get("cover")
            if cover_url and "default_cover" not in cover_url:
                print(
                    f"[Deezer] Найдено: {track.get('title')} — "
                    f"{track.get('artist', {}).get('name')} | 1000x1000"
                )
                return cover_url

        except urllib.error.HTTPError as e:
            print(f"[Deezer] HTTP {e.code} при поиске: {q}")
        except Exception as e:
            print(f"[Deezer] Ошибка при поиске '{q}': {e}")

    return None


def _itunes_search_cover(artist: str, title: str, album: str = "") -> Optional[str]:
    """Запасной вариант через iTunes — 600x600."""
    try:
        query = f"{artist} {title} {album}".strip()
        params = urllib.parse.urlencode({"term": query, "media": "music", "limit": "1"})
        resp = _http_get(f"https://itunes.apple.com/search?{params}", timeout=5)
        data = _json.loads(resp.decode("utf-8", "ignore"))
        if data.get("resultCount", 0) > 0:
            url = data["results"][0].get("artworkUrl100", "")
            if url:
                return url.replace("100x100bb", "600x600bb")
    except Exception as e:
        print(f"[iTunes] Ошибка: {e}")
    return None


def fetch_cover(artist: str, title: str, album: str = "") -> Optional[bytes]:
    """
    Главная функция получения обложки.
    1. Deezer (1000x1000, без ключей)
    2. iTunes (600x600, запасной)
    """
    if not artist or not title:
        return None

    key = (artist, title, album)
    if key in _cover_cache:
        return _cover_cache[key]

    # ── 1. Deezer ─────────────────────────────────────────────────────────
    img_url = _deezer_search_cover(artist, title, album)

    # ── 2. iTunes fallback ────────────────────────────────────────────────
    if not img_url:
        print("[cover] Deezer не нашёл, пробуем iTunes...")
        img_url = _itunes_search_cover(artist, title, album)

    # ── 3. Загрузка байтов ────────────────────────────────────────────────
    if img_url:
        try:
            img_bytes = _http_get(img_url, timeout=8)
            if len(img_bytes) > 500:
                _cover_cache[key] = img_bytes
                return img_bytes
        except Exception as e:
            print(f"[cover] Ошибка загрузки картинки: {e}")

    _cover_cache[key] = None
    return None


# ── Fallback-заглушка ─────────────────────────────────────────────────────────
_fallback_cover_bytes: Optional[bytes] = None


def get_fallback_cover() -> Optional[bytes]:
    """Заглушка-обложка — загружается один раз."""
    global _fallback_cover_bytes
    if _fallback_cover_bytes is not None:
        return _fallback_cover_bytes
    try:
        _fallback_cover_bytes = _http_get(
            "https://avatars.steamstatic.com/"
            "fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_full.jpg",
            timeout=5,
        )
        return _fallback_cover_bytes
    except Exception:
        return None


# ── Быстрый тест ──────────────────────────────────────────────────────────────
if __name__ == "__main__":
    info = get_track_info_sync()
    if info:
        print(f"Трек:    {info.title} — {info.artist}")
        print(f"Альбом:  {info.album}")
        print(f"Время:   {info.position_ms//1000}s / {info.duration_ms//1000}s")
        cover = fetch_cover(info.artist, info.title, info.album)
        print(f"Обложка: {len(cover or b'')} байт")
    else:
        print("Ничего не играет")
