#!/usr/bin/env python3
"""Generate stylized terrain and hazard texture PNGs for Shardring.

The output is intentionally simple, readable from the game camera, and fully
deterministic so terrain tuning can be regenerated without manual paint work.
"""

from __future__ import annotations

import math
import random
import struct
import zlib
from pathlib import Path


OUTPUT_DIR = Path("assets/art/textures/terrain")
TEXTURE_SIZE = 512


def _write_png(path: Path, width: int, height: int, pixels: list[tuple[int, int, int, int]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    raw_rows = []
    for y in range(height):
        row = bytearray([0])
        for x in range(width):
            row.extend(pixels[y * width + x])
        raw_rows.append(bytes(row))

    def chunk(kind: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + kind
            + data
            + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
        )

    payload = b"".join(
        [
            b"\x89PNG\r\n\x1a\n",
            chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)),
            chunk(b"IDAT", zlib.compress(b"".join(raw_rows), 9)),
            chunk(b"IEND", b""),
        ]
    )
    path.write_bytes(payload)


def _clamp_byte(value: float) -> int:
    return max(0, min(255, int(round(value))))


def _mix_color(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    t = max(0.0, min(1.0, t))
    return (
        _clamp_byte(a[0] + (b[0] - a[0]) * t),
        _clamp_byte(a[1] + (b[1] - a[1]) * t),
        _clamp_byte(a[2] + (b[2] - a[2]) * t),
    )


def _hash_noise(x: int, y: int, seed: int) -> float:
    value = (x * 374761393 + y * 668265263 + seed * 982451653) & 0xFFFFFFFF
    value = (value ^ (value >> 13)) * 1274126177 & 0xFFFFFFFF
    return (value ^ (value >> 16)) / 0xFFFFFFFF


def _smooth_noise(x: float, y: float, seed: int) -> float:
    ix = math.floor(x)
    iy = math.floor(y)
    fx = x - ix
    fy = y - iy
    fx = fx * fx * (3.0 - 2.0 * fx)
    fy = fy * fy * (3.0 - 2.0 * fy)
    a = _hash_noise(ix, iy, seed)
    b = _hash_noise(ix + 1, iy, seed)
    c = _hash_noise(ix, iy + 1, seed)
    d = _hash_noise(ix + 1, iy + 1, seed)
    return (a + (b - a) * fx) * (1.0 - fy) + (c + (d - c) * fx) * fy


def _generate_ground_albedo(
    seed: int,
    base: tuple[int, int, int],
    secondary: tuple[int, int, int],
    accent: tuple[int, int, int],
    name: str,
) -> None:
    rng = random.Random(seed)
    pixels: list[tuple[int, int, int, int]] = []
    strokes = [
        (
            rng.randrange(TEXTURE_SIZE),
            rng.randrange(TEXTURE_SIZE),
            rng.uniform(0.0, math.tau),
            rng.randrange(10, 28),
        )
        for _ in range(130)
    ]
    organic_blobs = [
        (
            rng.randrange(TEXTURE_SIZE),
            rng.randrange(TEXTURE_SIZE),
            rng.uniform(5.0, 18.0),
            rng.uniform(3.0, 12.0),
            rng.uniform(0.0, math.tau),
            rng.uniform(0.12, 0.28),
            rng.random() > 0.42,
        )
        for _ in range(110)
    ]

    for y in range(TEXTURE_SIZE):
        for x in range(TEXTURE_SIZE):
            u = x / TEXTURE_SIZE
            v = y / TEXTURE_SIZE
            broad = _smooth_noise(u * 6.0, v * 6.0, seed)
            detail = _smooth_noise(u * 28.0, v * 28.0, seed + 41)
            color = _mix_color(base, secondary, max(0.0, broad - 0.32) * 0.34)

            for cx, cy, radius_x, radius_y, angle, strength, uses_accent in organic_blobs:
                dx = x - cx
                dy = y - cy
                local_x = dx * math.cos(angle) + dy * math.sin(angle)
                local_y = -dx * math.sin(angle) + dy * math.cos(angle)
                distance = (local_x / radius_x) ** 2 + (local_y / radius_y) ** 2
                if distance < 1.0:
                    organic_amount = (1.0 - distance) ** 1.8
                    target_color = accent if uses_accent else secondary
                    color = _mix_color(color, target_color, strength * organic_amount)

            stroke_amount = 0.0
            for sx, sy, angle, length in strokes:
                dx = x - sx
                dy = y - sy
                along = dx * math.cos(angle) + dy * math.sin(angle)
                across = abs(-dx * math.sin(angle) + dy * math.cos(angle))
                if 0.0 <= along <= length and across <= 0.9:
                    stroke_amount = max(stroke_amount, 1.0 - across)
            if stroke_amount > 0.0:
                color = _mix_color(color, secondary, 0.22 * stroke_amount)

            shade = 1.0 + (detail - 0.5) * 0.09
            pixels.append(
                (
                    _clamp_byte(color[0] * shade),
                    _clamp_byte(color[1] * shade),
                    _clamp_byte(color[2] * shade),
                    255,
                )
            )

    _write_png(OUTPUT_DIR / f"{name}_albedo.png", TEXTURE_SIZE, TEXTURE_SIZE, pixels)


def _generate_ground_detail(seed: int, name: str) -> None:
    pixels: list[tuple[int, int, int, int]] = []
    for y in range(TEXTURE_SIZE):
        for x in range(TEXTURE_SIZE):
            u = x / TEXTURE_SIZE
            v = y / TEXTURE_SIZE
            detail = _smooth_noise(u * 18.0, v * 18.0, seed)
            fine = _smooth_noise(u * 64.0, v * 64.0, seed + 13)
            value = 128 + (detail - 0.5) * 58 + (fine - 0.5) * 18
            if _hash_noise(x, y, seed + 29) > 0.9975:
                value -= 46
            gray = _clamp_byte(value)
            pixels.append((gray, gray, gray, 255))
    _write_png(OUTPUT_DIR / f"{name}_detail.png", TEXTURE_SIZE, TEXTURE_SIZE, pixels)


def _generate_warning_stripes() -> None:
    pixels: list[tuple[int, int, int, int]] = []
    for y in range(TEXTURE_SIZE):
        for x in range(TEXTURE_SIZE):
            stripe = ((x + y) // 36) % 2
            noise = _smooth_noise(x / 18.0, y / 18.0, 70)
            base = (255, 206, 52) if stripe == 0 else (255, 128, 38)
            color = _mix_color(base, (255, 72, 28), max(0.0, noise - 0.68) * 0.45)
            pixels.append((*color, 255))
    _write_png(OUTPUT_DIR / "hazard_warning_stripes.png", TEXTURE_SIZE, TEXTURE_SIZE, pixels)


def _generate_lava_flow() -> None:
    pixels: list[tuple[int, int, int, int]] = []
    for y in range(TEXTURE_SIZE):
        for x in range(TEXTURE_SIZE):
            u = x / TEXTURE_SIZE
            v = y / TEXTURE_SIZE
            wave = math.sin((u * 8.0 + _smooth_noise(u * 4.0, v * 8.0, 91)) * math.tau)
            crack = _smooth_noise(u * 20.0, v * 20.0, 92)
            color = _mix_color((170, 34, 18), (255, 104, 18), 0.48 + wave * 0.22)
            if crack < 0.28:
                color = _mix_color(color, (45, 18, 12), 0.7)
            if crack > 0.82:
                color = _mix_color(color, (255, 218, 72), 0.35)
            pixels.append((*color, 255))
    _write_png(OUTPUT_DIR / "hazard_lava_flow.png", TEXTURE_SIZE, TEXTURE_SIZE, pixels)


def _generate_ice_cracks() -> None:
    pixels: list[tuple[int, int, int, int]] = []
    crack_lines = [(0.18, 0.2, 1.0), (0.42, -0.35, 0.52), (0.66, 0.58, -0.18), (0.82, -0.9, 0.94)]
    for y in range(TEXTURE_SIZE):
        for x in range(TEXTURE_SIZE):
            u = x / TEXTURE_SIZE
            v = y / TEXTURE_SIZE
            color = _mix_color((118, 214, 239), (221, 251, 255), _smooth_noise(u * 10, v * 10, 111))
            crack_strength = 0.0
            for offset, slope, intercept in crack_lines:
                distance = abs(v - (slope * (u - offset) + intercept))
                crack_strength = max(crack_strength, max(0.0, 1.0 - distance * 85.0))
            color = _mix_color(color, (42, 124, 174), crack_strength * 0.68)
            pixels.append((*color, 255))
    _write_png(OUTPUT_DIR / "hazard_ice_cracks.png", TEXTURE_SIZE, TEXTURE_SIZE, pixels)


def _generate_collapse_cracks() -> None:
    pixels: list[tuple[int, int, int, int]] = []
    for y in range(TEXTURE_SIZE):
        for x in range(TEXTURE_SIZE):
            u = x / TEXTURE_SIZE
            v = y / TEXTURE_SIZE
            n = _smooth_noise(u * 14.0, v * 14.0, 131)
            color = _mix_color((125, 85, 45), (242, 117, 28), max(0.0, n - 0.42))
            crack = abs(_smooth_noise(u * 8.0, v * 8.0, 132) - 0.5)
            if crack < 0.035:
                color = _mix_color(color, (30, 24, 20), 0.82)
            pixels.append((*color, 255))
    _write_png(OUTPUT_DIR / "hazard_collapse_cracks.png", TEXTURE_SIZE, TEXTURE_SIZE, pixels)


def main() -> None:
    _generate_ground_albedo(11, (78, 119, 67), (104, 148, 79), (130, 112, 68), "terrain_meadow")
    _generate_ground_detail(12, "terrain_meadow")
    _generate_ground_albedo(21, (104, 97, 67), (129, 118, 77), (78, 91, 62), "terrain_clay")
    _generate_ground_detail(22, "terrain_clay")
    _generate_warning_stripes()
    _generate_lava_flow()
    _generate_ice_cracks()
    _generate_collapse_cracks()


if __name__ == "__main__":
    main()
