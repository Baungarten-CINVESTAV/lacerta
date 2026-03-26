"""
Lacerta-HMI Designer – main.py
PySide6-based HMI layout designer with 8 indicator types, canvas grid/snap/zoom,
properties panel, value preview, and JSON export.
"""

from __future__ import annotations

import base64
import io
import json
import math
import os
import struct
import subprocess
import zlib
from typing import Optional

from PySide6.QtCore import (
    QPoint, QPointF, QRect, QRectF, QSizeF, Qt, Signal, QSize, QThread, QTimer,
    QDateTime, QSettings
)
from PySide6.QtGui import (
    QBrush, QColor, QFont, QFontMetrics, QImage, QPainter, QPainterPath,
    QPen, QPixmap, QRadialGradient, QConicalGradient, QLinearGradient,
    QPolygonF, QTransform, QAction, QIcon, QMouseEvent,
)
from PySide6.QtWidgets import (
    QApplication, QCheckBox, QColorDialog, QComboBox, QDialog,
    QDialogButtonBox, QDoubleSpinBox, QFileDialog, QFormLayout,
    QGraphicsItem, QGraphicsRectItem, QGraphicsScene, QGraphicsView,
    QGroupBox, QHBoxLayout, QInputDialog, QLabel, QLineEdit, QListWidget,
    QListWidgetItem, QMainWindow, QMenu, QMessageBox, QPushButton,
    QScrollArea, QSizePolicy, QSlider, QSpinBox, QSplitter,
    QStackedWidget, QStatusBar, QTabWidget, QTextEdit, QToolBar,
    QTreeWidget, QTreeWidgetItem,
    QFontComboBox,
    QVBoxLayout, QWidget, QFrame,
)
import sys

# ── Resolve base directories (works in both dev and frozen/PyInstaller mode) ──
if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
    _BUNDLE_DIR = sys._MEIPASS                        # bundled read-only resources
    _DATA_DIR   = os.path.dirname(sys.executable)    # user-writable data next to exe
else:
    _BUNDLE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    _DATA_DIR   = _BUNDLE_DIR

# Make tools/scripts/python importable
sys.path.insert(0, os.path.join(_BUNDLE_DIR, "tools", "scripts", "python"))
from program_template import build as _build_firmware

# ─────────────────────────────────────────────
#  CONSTANTS
# ─────────────────────────────────────────────
DEFAULT_CANVAS_W   = 640
DEFAULT_CANVAS_H   = 480
DEFAULT_GRID_SIZE  = 20
HANDLE_SIZE        = 10
MIN_ITEM_SIZE      = 20
SELECTION_COLOR    = QColor("#FFD600")   # yellow highlight
CANVAS_BG          = QColor("#FFFFFF")
SCENE_BG           = QColor("#3C3C3C")  # gray surround

INDICATOR_TYPES = [
    # ── Classic gauges ──────────────────────────────────────────────
    "linear_h", "linear_v", "graph", "seven_seg",
    "velocimeter", "rotational", "tank", "battery", "compass",
    # ── Status & Alerts ─────────────────────────────────────────────
    "led", "warning_badge", "traffic_light", "toggle_switch",
    # ── Data Readout ────────────────────────────────────────────────
    "numeric_readout", "state_label", "trend_arrow",
    # ── Gauges & Meters ─────────────────────────────────────────────
    "arc_gauge", "dual_bar", "thermometer",
    # ── Process & Flow ──────────────────────────────────────────────
    "pipe_h", "pipe_v", "valve",
    # ── Structural ──────────────────────────────────────────────────
    "text_label", "rect_container", "divider",
    # ── Shapes ──────────────────────────────────────────────────────
    "shape_rect", "shape_ellipse", "shape_triangle",
    "shape_trapezoid", "shape_arrow", "shape_line", "shape_bezier",
]

INDICATOR_LABELS = {
    # Classic
    "linear_h":       "Linear Horizontal",
    "linear_v":       "Linear Vertical",
    "graph":          "Graph",
    "seven_seg":      "7-Segment",
    "velocimeter":    "Velocimeter",
    "rotational":     "Rotational",
    "tank":           "Tank Level",
    "battery":        "Battery",
    "compass":        "Compass",
    # Status & Alerts
    "led":            "LED",
    "warning_badge":  "Warning Badge",
    "traffic_light":  "Traffic Light",
    "toggle_switch":  "Toggle Switch",
    # Data Readout
    "numeric_readout": "Numeric Readout",
    "state_label":    "State Label",
    "trend_arrow":    "Trend Arrow",
    # Gauges & Meters
    "arc_gauge":      "Arc Gauge",
    "dual_bar":       "Dual Bar",
    "thermometer":    "Thermometer",
    # Process & Flow
    "pipe_h":         "Pipe (H)",
    "pipe_v":         "Pipe (V)",
    "valve":          "Valve",
    # Structural
    "text_label":     "Text Label",
    "rect_container": "Container",
    "divider":        "Divider",
    # Shapes
    "shape_rect":      "Rectangle",
    "shape_ellipse":   "Ellipse",
    "shape_triangle":  "Triangle",
    "shape_trapezoid": "Trapezoid",
    "shape_arrow":     "Arrow",
    "shape_line":      "Line",
    "shape_bezier":    "Bezier Curve",
}

DEFAULT_SIZES = {
    # Classic
    "linear_h":       (160, 40),
    "linear_v":       (40, 160),
    "graph":          (120, 120),
    "seven_seg":      (70, 130),
    "velocimeter":    (160, 160),
    "rotational":     (140, 140),
    "tank":           (60, 160),
    "battery":        (120, 50),
    "compass":        (150, 150),
    # Status & Alerts
    "led":            (40, 40),
    "warning_badge":  (80, 60),
    "traffic_light":  (40, 100),
    "toggle_switch":  (60, 30),
    # Data Readout
    "numeric_readout": (120, 60),
    "state_label":    (120, 40),
    "trend_arrow":    (60, 60),
    # Gauges & Meters
    "arc_gauge":      (160, 120),
    "dual_bar":       (160, 60),
    "thermometer":    (40, 160),
    # Process & Flow
    "pipe_h":         (80, 20),
    "pipe_v":         (20, 80),
    "valve":          (44, 44),
    # Structural
    "text_label":     (120, 30),
    "rect_container": (200, 120),
    "divider":        (160, 4),
    # Shapes
    "shape_rect":      (120, 80),
    "shape_ellipse":   (120, 80),
    "shape_triangle":  (100, 100),
    "shape_trapezoid": (120, 80),
    "shape_arrow":     (120, 60),
    "shape_line":      (120, 60),
    "shape_bezier":    (160, 100),
}

# Palette sidebar categories
INDICATOR_CATEGORIES = [
    ("Classic Gauges",   ["linear_h", "linear_v", "graph", "seven_seg",
                          "velocimeter", "rotational", "tank", "battery", "compass"]),
    ("Status & Alerts",  ["led", "warning_badge", "traffic_light", "toggle_switch"]),
    ("Data Readout",     ["numeric_readout", "state_label", "trend_arrow"]),
    ("Gauges & Meters",  ["arc_gauge", "dual_bar", "thermometer"]),
    ("Process & Flow",   ["pipe_h", "pipe_v", "valve"]),
    ("Structural",       ["text_label", "rect_container", "divider"]),
    ("Shapes",         ["shape_rect", "shape_ellipse", "shape_triangle",
                        "shape_trapezoid", "shape_arrow", "shape_line", "shape_bezier"]),
]

# ─────────────────────────────────────────────
#  INDICATOR DRAWING ENGINE
# ─────────────────────────────────────────────

def _accent(color: QColor) -> QColor:
    """Lighter version of the accent colour for glow / highlight."""
    return color.lighter(150)

def _quantize_qimage(img: QImage, bit_depth: int) -> QImage:
    """Quantize a full-colour QImage to the target bit depth for live canvas preview."""
    from PIL import Image as PILImage
    import numpy as np
    img = img.convertToFormat(QImage.Format_RGB888)
    w, h = img.width(), img.height()
    stride = img.bytesPerLine()
    pil = PILImage.frombuffer('RGB', (w, h), img.constBits(), 'raw', 'RGB', stride, 1)
    if bit_depth == 16:
        # Simulate RGB565: R=5 bits, G=6 bits, B=5 bits
        arr = np.array(pil, dtype=np.uint8)
        arr[:, :, 0] = (arr[:, :, 0] >> 3) << 3   # R: keep top 5
        arr[:, :, 1] = (arr[:, :, 1] >> 2) << 2   # G: keep top 6
        arr[:, :, 2] = (arr[:, :, 2] >> 3) << 3   # B: keep top 5
        pil = PILImage.fromarray(arr, 'RGB')
    elif bit_depth == 8:
        pil = pil.quantize(colors=256, dither=1).convert('RGB')
    elif bit_depth == 4:
        pil = pil.quantize(colors=16, dither=1).convert('RGB')
    elif bit_depth == 2:
        # 4 gray levels
        arr = np.array(pil.convert('L'), dtype=np.uint8)
        arr = ((arr >> 6) * 85).astype(np.uint8)
        pil = PILImage.fromarray(arr, 'L').convert('RGB')
    elif bit_depth == 7:  # RGB232 hardware format: R=2, G=3, B=2
        arr = np.array(pil, dtype=np.uint8)
        arr[:, :, 0] = (arr[:, :, 0] >> 6) << 6   # R: keep top 2 bits (4 levels)
        arr[:, :, 1] = (arr[:, :, 1] >> 5) << 5   # G: keep top 3 bits (8 levels)
        arr[:, :, 2] = (arr[:, :, 2] >> 6) << 6   # B: keep top 2 bits (4 levels)
        pil = PILImage.fromarray(arr, 'RGB')
    elif bit_depth == 1:
        arr = np.array(pil.convert('L'), dtype=np.uint8)
        arr = np.where(arr >= 128, np.uint8(255), np.uint8(0))
        pil = PILImage.fromarray(arr.astype(np.uint8), 'L').convert('RGB')
    raw = pil.tobytes()
    out = QImage(raw, w, h, w * 3, QImage.Format_RGB888)
    return out.copy()  # .copy() ensures Qt owns the pixel buffer


def _quantize_color(c: QColor, bit_depth: int) -> QColor:
    """Truncate a single QColor to the target bit depth (matches _quantize_qimage channel masking)."""
    r, g, b = c.red(), c.green(), c.blue()
    if bit_depth == 16:          # RGB565
        r = (r >> 3) << 3
        g = (g >> 2) << 2
        b = (b >> 3) << 3
    elif bit_depth == 8:         # 3-3-2
        r = (r >> 5) << 5
        g = (g >> 5) << 5
        b = (b >> 6) << 6
    elif bit_depth == 7:          # RGB232 hardware format
        r = (r >> 6) << 6
        g = (g >> 5) << 5
        b = (b >> 6) << 6
    elif bit_depth == 4:         # 2-2-2 (4 levels per channel)
        r = (r >> 6) * 85
        g = (g >> 6) * 85
        b = (b >> 6) * 85
    elif bit_depth == 2:         # 4 grayscale levels (matches _quantize_qimage)
        gray = int(0.299 * r + 0.587 * g + 0.114 * b)
        r = g = b = (gray >> 6) * 85
    elif bit_depth == 1:         # mono (matches _quantize_qimage)
        gray = int(0.299 * r + 0.587 * g + 0.114 * b)
        r = g = b = 255 if gray >= 128 else 0
    return QColor(r, g, b)


def _theme(color: QColor, bit_depth: int):
    # Returns (bg, pen, fill, accent, tick)
    if bit_depth == 1:
        return QColor(Qt.white), QColor(Qt.black), QColor(Qt.black), QColor(Qt.black), QColor(Qt.black)
    elif bit_depth == 2:
        return QColor(Qt.white), QColor(Qt.black), QColor("#555555"), QColor("#AAAAAA"), QColor("#888888")
    else:
        bg   = QColor("#1A1A2E")
        pen  = color.darker(130)
        fill = QColor(color)
        acc  = _accent(color)
        tick = QColor("#888888")
        if bit_depth in (4, 7, 8, 16):
            bg   = _quantize_color(bg,   bit_depth)
            pen  = _quantize_color(pen,  bit_depth)
            fill = _quantize_color(fill, bit_depth)
            acc  = _quantize_color(acc,  bit_depth)
            tick = _quantize_color(tick, bit_depth)
        return bg, pen, fill, acc, tick

def _draw_linear_h(painter: QPainter, rect: QRectF, fill_fraction: float,
                   color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Horizontal bar gauge – fixed full-width gradient clipped to fill fraction."""
    r = rect.adjusted(1, 1, -1, -1)
    radius = r.height() / 4
    bg, pen, fill, acc, tick = _theme(color, bit_depth)

    # Background track
    painter.setPen(QPen(pen, 1.5))
    painter.setBrush(bg)
    #painter.drawRoundedRect(r, radius, radius)
    painter.drawRect(r)

    if not empty and fill_fraction > 0:
        if bit_depth < 24:
            painter.setPen(Qt.NoPen)
            painter.setBrush(fill)
        else:
            grad = QLinearGradient(r.topLeft(), r.topRight())
            grad.setColorAt(0.0, color.darker(120))
            grad.setColorAt(0.5, color)
            grad.setColorAt(1.0, acc)
            painter.setPen(Qt.NoPen)
            painter.setBrush(grad)
        
        clip_path = QPainterPath()
        #clip_path.addRoundedRect(r, radius, radius)
        clip_path.addRect(r)
        painter.setClipPath(clip_path)
        fill_rect = QRectF(r.left(), r.top(), r.width() * fill_fraction, r.height())
        painter.drawRect(fill_rect)
        painter.setClipping(False)

    # Tick marks
    painter.setPen(QPen(tick, 0.8))
    ticks = 10
    for i in range(1, ticks):
        x = r.left() + r.width() * i / ticks
        y1 = r.top() + r.height() * 0.6
        y2 = r.bottom()
        painter.drawLine(QPointF(x, y1), QPointF(x, y2))


def _draw_linear_v(painter: QPainter, rect: QRectF, fill_fraction: float,
                   color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Vertical bar gauge (fills bottom → top)."""
    r = rect.adjusted(1, 1, -1, -1)
    radius = r.width() / 4
    bg, pen, fill, acc, tick = _theme(color, bit_depth)

    painter.setPen(QPen(pen, 1.5))
    painter.setBrush(bg)
    #painter.drawRoundedRect(r, radius, radius)
    painter.drawRect(r)

    if not empty and fill_fraction > 0:
        fill_h = r.height() * fill_fraction
        if bit_depth < 24:
            painter.setPen(Qt.NoPen)
            painter.setBrush(fill)
        else:
            grad = QLinearGradient(r.bottomLeft(), r.topLeft())
            grad.setColorAt(0.0, color.darker(120))
            grad.setColorAt(0.5, color)
            grad.setColorAt(1.0, acc)
            painter.setPen(Qt.NoPen)
            painter.setBrush(grad)
        
        path = QPainterPath()
        #path.addRoundedRect(r, radius, radius)
        path.addRect(r)
        painter.setClipPath(path)
        
        fill_rect = QRectF(r.left(), r.bottom() - fill_h, r.width(), fill_h)
        painter.drawRect(fill_rect)
        painter.setClipping(False)

    painter.setPen(QPen(tick, 0.8))
    ticks = 10
    for i in range(1, ticks):
        y = r.bottom() - r.height() * i / ticks
        x1 = r.left()
        x2 = r.left() + r.width() * 0.4
        painter.drawLine(QPointF(x1, y), QPointF(x2, y))

def _draw_graph_indicator(painter: QPainter, rect: QRectF, value_fraction: float,
                          color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Draw indicator that looks like a graph with X/Y ticks."""

    r = rect.adjusted(1, 1, -1, -1)

    bg, pen, fill, acc, tick = _theme(color, bit_depth)

    # Background
    painter.setPen(QPen(pen, 1.5))
    painter.setBrush(bg)
    painter.drawRect(r)

    # --- axes ---
    painter.setPen(QPen(pen, 1.2))

    # X axis
    painter.drawLine(
        QPointF(r.left(), r.bottom()),
        QPointF(r.right(), r.bottom())
    )

    # Y axis
    painter.drawLine(
        QPointF(r.left(), r.top()),
        QPointF(r.left(), r.bottom())
    )

    # --- ticks ---
    painter.setPen(QPen(tick, 0.8))

    x_ticks = 10
    y_ticks = 6

    # X ticks
    for i in range(1, x_ticks + 1):
        x = r.left() + r.width() * i / x_ticks
        painter.drawLine(
            QPointF(x, r.bottom()),
            QPointF(x, r.bottom() - r.height() * 0.05)
        )

    # Y ticks
    for i in range(1, y_ticks + 1):
        y = r.bottom() - r.height() * i / y_ticks
        painter.drawLine(
            QPointF(r.left(), y),
            QPointF(r.left() + r.width() * 0.04, y)
        )

    # --- value indicator ---
    if not empty:

        x_val = r.left() + r.width() * value_fraction

        if bit_depth < 24:
            painter.setPen(QPen(fill, 2))
        else:
            grad = QLinearGradient(r.topLeft(), r.bottomLeft())
            grad.setColorAt(0.0, acc)
            grad.setColorAt(1.0, color)
            painter.setPen(QPen(grad, 2))

        # vertical value line
        painter.drawLine(
            QPointF(x_val, r.bottom()),
            QPointF(x_val, r.top())
        )

# Seven-segment digit encoding (segments a-g)
_SEG7_DEC = {
    '0': 0b1111110, '1': 0b0110000, '2': 0b1101101, '3': 0b1111001,
    '4': 0b0110011, '5': 0b1011011, '6': 0b1011111, '7': 0b1110000,
    '8': 0b1111111, '9': 0b1111011, '-': 0b0000001, ' ': 0b0000000,
}
_SEG7_HEX = dict(_SEG7_DEC)
_SEG7_HEX.update({
    'A': 0b1110111, 'B': 0b0011111, 'C': 0b1001110,
    'D': 0b0111101, 'E': 0b1001111, 'F': 0b1000111,
})
_SEG7 = _SEG7_DEC


def _seg7_paths(rect: QRectF, italic: bool = False) -> list:
    w, h = rect.width(), rect.height()
    t = max(3.0, min(w, h) * 0.09)   # segment thickness
    g = max(1.0, t * 0.15)           # gap between segments

    ox, oy = rect.left(), rect.top()
    shear = 0.18 if italic else 0.0

    def shear_x(px, py):
        mid_y = oy + h / 2
        return px + shear * (mid_y - py)

    cx_left  = ox + t * 0.5
    cx_right = ox + w - t * 0.5
    cy_top   = oy + t * 0.5
    cy_mid   = oy + h * 0.5
    cy_bot   = oy + h - t * 0.5

    def hrect(cy): 
        p = QPainterPath()
        pts = [
            QPointF(shear_x(cx_left + g + t * 0.5, cy - t * 0.5), cy - t * 0.5),
            QPointF(shear_x(cx_right - g - t * 0.5, cy - t * 0.5), cy - t * 0.5),
            QPointF(shear_x(cx_right - g,           cy),           cy),
            QPointF(shear_x(cx_right - g - t * 0.5, cy + t * 0.5), cy + t * 0.5),
            QPointF(shear_x(cx_left + g + t * 0.5, cy + t * 0.5), cy + t * 0.5),
            QPointF(shear_x(cx_left + g,           cy),           cy),
        ]
        p.moveTo(pts[0])
        for pt in pts[1:]:
            p.lineTo(pt)
        p.closeSubpath()
        return p

    def vrect(cx, cy1, cy2):
        p = QPainterPath()
        pts = [
            QPointF(shear_x(cx,           cy1 + g + t * 0.5), cy1 + g + t * 0.5),
            QPointF(shear_x(cx + t * 0.5, cy1 + g + t),       cy1 + g + t),
            QPointF(shear_x(cx + t * 0.5, cy2 - g - t),       cy2 - g - t),
            QPointF(shear_x(cx,           cy2 - g - t * 0.5), cy2 - g - t * 0.5),
            QPointF(shear_x(cx - t * 0.5, cy2 - g - t),       cy2 - g - t),
            QPointF(shear_x(cx - t * 0.5, cy1 + g + t),       cy1 + g + t),
        ]
        p.moveTo(pts[0])
        for pt in pts[1:]:
            p.lineTo(pt)
        p.closeSubpath()
        return p

    segs = [
        hrect(cy_top),                         # a - top
        vrect(cx_right, cy_top, cy_mid),       # b - top-right
        vrect(cx_right, cy_mid, cy_bot),       # c - bot-right
        hrect(cy_bot),                         # d - bottom
        vrect(cx_left, cy_mid, cy_bot),        # e - bot-left
        vrect(cx_left, cy_top, cy_mid),        # f - top-left
        hrect(cy_mid),                         # g - middle
    ]
    return segs


def _draw_seven_seg(painter: QPainter, rect: QRectF, fill_fraction: float,
                    color: QColor, empty: bool,
                    italic: bool = False, hex_mode: bool = False, bit_depth: int = 32) -> None:
    padding_x = rect.height() * 0.15 if italic else 4
    if bit_depth in (4, 7, 8, 16):
        color = _quantize_color(color, bit_depth)

    if bit_depth == 1:
        bg = QColor(Qt.white)
        active_brush = QColor(Qt.black)
        off_brush = QColor(Qt.transparent)
        outline_pen = Qt.NoPen
        bg_pen = QPen(Qt.black, 1.5)
    elif bit_depth == 2:
        bg = QColor(Qt.white)
        active_brush = QColor(Qt.black)
        off_brush = QColor("#DDDDDD")
        outline_pen = Qt.NoPen
        bg_pen = QPen(Qt.black, 1.5)
    else:
        bg = QColor("#0D0D0D")
        active_brush = color
        c_off = QColor(color)
        c_off.setAlpha(40)
        off_brush = c_off
        c_glow = QColor(color)
        c_glow.setAlpha(70)
        outline_pen = QPen(c_glow, 1.5)
        bg_pen = Qt.NoPen

    painter.setPen(bg_pen)
    painter.setBrush(bg)
    #painter.drawRoundedRect(rect, 6, 6)
    painter.drawRect(rect)

    table = _SEG7_HEX if hex_mode else _SEG7_DEC
    max_digit = 15 if hex_mode else 9
    
    if empty or fill_fraction < -0.05:
        char = ' '
        empty = True
    elif fill_fraction < 0.0:
        char = '-'
        empty = False
    else:
        digit_val = int(round(fill_fraction * max_digit))
        if hex_mode:
            char = format(min(15, digit_val), 'X')
        else:
            char = str(min(9, digit_val))
            
    mask = table.get(char, 0b1111111)
    seg_paths = _seg7_paths(rect.adjusted(padding_x, 8, -padding_x, -8), italic=italic)

    for i, path in enumerate(seg_paths):
        bit = (mask >> (6 - i)) & 1
        active = (not empty) and bool(bit)
        if active:
            painter.setPen(outline_pen)
            painter.setBrush(active_brush)
        else:
            painter.setPen(Qt.NoPen)
            painter.setBrush(off_brush)
        painter.drawPath(path)


def _draw_velocimeter(painter: QPainter, rect: QRectF, fill_fraction: float,
                      color: QColor, empty: bool, bit_depth: int = 32) -> None:
    cx = rect.center().x()
    cy = rect.center().y()
    dim = min(rect.width(), rect.height()) * 0.96
    r_outer = dim / 2
    r_needle = r_outer * 0.70

    START_DEG = 225
    SPAN_DEG  = 270

    arc_pen_w = max(4.0, r_outer * 0.12)
    arc_r = r_outer * 0.78
    arc_rect = QRectF(cx - arc_r, cy - arc_r, arc_r * 2, arc_r * 2)

    bg, pen, fill, acc, tick = _theme(color, bit_depth)

    if bit_depth <= 2:
        center_bg = Qt.white
        ring_pen = QPen(Qt.black, 2)
        track_pen = QPen(QColor("#DDDDDD"), arc_pen_w, Qt.SolidLine, Qt.RoundCap) if bit_depth == 2 else Qt.NoPen
        fill_pen = QPen(Qt.black if bit_depth == 1 else QColor("#555555"), arc_pen_w, Qt.SolidLine, Qt.RoundCap)
        needle_pen = QPen(Qt.black, 2, Qt.SolidLine, Qt.RoundCap)
        tick_pen = QPen(tick, 1.2)
        cap_brush = QColor(Qt.black)
    else:
        center_bg = QColor("#0D0D1A")
        ring_pen = QPen(color.darker(140), 2)
        track_pen = QPen(QColor("#333333"), arc_pen_w, Qt.SolidLine, Qt.RoundCap)
        fill_pen = QPen(color, arc_pen_w, Qt.SolidLine, Qt.RoundCap)
        needle_pen = QPen(Qt.white, 2, Qt.SolidLine, Qt.RoundCap)
        tick_pen = QPen(QColor("#666666"), 1.2)
        cap_brush = QColor("#888888")

    painter.setPen(Qt.NoPen)
    painter.setBrush(center_bg)
    painter.drawEllipse(QPointF(cx, cy), r_outer, r_outer)

    painter.setPen(ring_pen)
    painter.setBrush(Qt.NoBrush)
    painter.drawEllipse(QPointF(cx, cy), r_outer * 0.97, r_outer * 0.97)

    if track_pen != Qt.NoPen:
        painter.setPen(track_pen)
        painter.setBrush(Qt.NoBrush)
        painter.drawArc(arc_rect, int(START_DEG * 16), int(-SPAN_DEG * 16))

    if not empty and fill_fraction > 0:
        clamp = max(0.0, min(1.0, fill_fraction))
        painter.setPen(fill_pen)
        painter.setBrush(Qt.NoBrush)
        painter.drawArc(arc_rect, int(START_DEG * 16), int(-SPAN_DEG * clamp * 16))

        needle_deg  = START_DEG - SPAN_DEG * clamp
        needle_rad  = math.radians(needle_deg)
        nx = cx + r_needle * math.cos(needle_rad)
        ny = cy - r_needle * math.sin(needle_rad)
        painter.setPen(needle_pen)
        painter.drawLine(QPointF(cx, cy), QPointF(nx, ny))

    painter.setPen(tick_pen)
    for i in range(11):
        ang = math.radians(START_DEG - SPAN_DEG * i / 10)
        r1 = r_outer * 0.82
        r2 = r_outer * 0.93
        painter.drawLine(
            QPointF(cx + r1 * math.cos(ang), cy - r1 * math.sin(ang)),
            QPointF(cx + r2 * math.cos(ang), cy - r2 * math.sin(ang)),
        )

    painter.setPen(Qt.NoPen)
    painter.setBrush(cap_brush)
    painter.drawEllipse(QPointF(cx, cy), r_outer * 0.07, r_outer * 0.07)


def _draw_rotational(painter: QPainter, rect: QRectF, fill_fraction: float,
                     color: QColor, empty: bool, bit_depth: int = 32) -> None:
    cx = rect.center().x()
    cy = rect.center().y()
    r = min(rect.width(), rect.height()) / 2 - 2

    bg, pen, fill, acc, tick = _theme(color, bit_depth)

    painter.setPen(Qt.NoPen)
    painter.setBrush(bg)
    painter.drawEllipse(QPointF(cx, cy), r, r)

    painter.setPen(QPen(pen, 2))
    painter.setBrush(Qt.NoBrush)
    painter.drawEllipse(QPointF(cx, cy), r, r)

    if not empty and fill_fraction > 0:
        span = int(fill_fraction * 360 * 16)
        arc_r = QRectF(cx - r * 0.9, cy - r * 0.9, r * 1.8, r * 1.8)
        
        if bit_depth < 24:
            painter.setBrush(QBrush(fill))
            painter.setPen(Qt.NoPen)
        else:
            grad = QRadialGradient(cx, cy, r)
            grad.setColorAt(0, acc)
            grad.setColorAt(0.7, color)
            grad.setColorAt(1.0, color.darker(140))
            painter.setBrush(QBrush(grad))
            painter.setPen(Qt.NoPen)

        painter.drawPie(arc_r, 90 * 16, span)

    inner_pen = QPen(Qt.black, 0.8) if bit_depth == 1 else QPen(QColor("#333355"), 0.8)
    painter.setPen(inner_pen)
    painter.setBrush(Qt.NoBrush)
    for frac in (0.4, 0.7):
        rr = r * frac
        painter.drawEllipse(QPointF(cx, cy), rr, rr)


def _draw_tank(painter: QPainter, rect: QRectF, fill_fraction: float,
               color: QColor, empty: bool, bit_depth: int = 32) -> None:
    r = rect.adjusted(2, 2, -2, -2)
    radius = r.width() * 0.25

    bg, pen, fill, acc, tick = _theme(color, bit_depth)
    tank_bg = Qt.white if bit_depth <= 2 else QColor("#0D1A1A")

    painter.setPen(QPen(pen, 2))
    painter.setBrush(tank_bg)
    #painter.drawRoundedRect(r, radius, radius)
    painter.drawRect(r)

    if not empty and fill_fraction > 0:
        inner = r.adjusted(3, 3, -3, -3)
        fill_h = inner.height() * fill_fraction
        fill_rect = QRectF(inner.left(), inner.bottom() - fill_h,
                           inner.width(), fill_h)
        
        if bit_depth < 24:
            painter.setPen(Qt.NoPen)
            painter.setBrush(QBrush(fill))
        else:
            grad = QLinearGradient(inner.bottomLeft(), inner.topLeft())
            grad.setColorAt(0, color.darker(130))
            grad.setColorAt(0.6, color)
            grad.setColorAt(1.0, color.lighter(130))
            painter.setPen(Qt.NoPen)
            painter.setBrush(QBrush(grad))
            
        path = QPainterPath()
        #path.addRoundedRect(inner, radius * 0.8, radius * 0.8)
        path.addRect(inner)
        painter.setClipPath(path)
        painter.drawRect(fill_rect)
        painter.setClipping(False)

        if bit_depth >= 24:
            hi = QColor(255, 255, 255, 40)
            painter.setBrush(hi)
            bw = inner.width() * 0.25
            bh = fill_h * 0.25
            painter.drawEllipse(QRectF(inner.left() + 4, inner.bottom() - fill_h + 4, bw, bh))

    level_pen = Qt.black if bit_depth <= 2 else QColor("#4A4A4A")
    painter.setPen(QPen(level_pen, 0.8))
    inner = r.adjusted(3, 3, -3, -3)
    for i in range(1, 5):
        y = inner.top() + inner.height() * i / 5
        painter.drawLine(QPointF(inner.left(), y), QPointF(inner.right(), y))


def _draw_battery(painter: QPainter, rect: QRectF, fill_fraction: float,
                  color: QColor, empty: bool, bit_depth: int = 32) -> None:
    r = rect.adjusted(1, 1, -1, -1)
    nib_w = r.width() * 0.06
    body = QRectF(r.left(), r.top(), r.width() - nib_w, r.height())
    nib = QRectF(body.right(), r.top() + r.height() * 0.3,
                 nib_w, r.height() * 0.4)

    bg, pen, fill, acc, tick = _theme(color, bit_depth)

    # Body
    painter.setPen(QPen(pen, 2))
    painter.setBrush(bg)
    #painter.drawRoundedRect(body, 3, 3)
    painter.drawRect(body)

    # Terminal nib
    painter.setPen(Qt.NoPen)
    painter.setBrush(Qt.black if bit_depth <= 2 else color.darker(120))
    #painter.drawRoundedRect(nib, 2, 2)
    painter.drawRect(nib)

    cells = 5
    gap = 3
    cell_w = (body.width() - 6 - gap * (cells - 1)) / cells
    c_top = body.top() + 4
    c_h = body.height() - 8

    filled_cells = round(fill_fraction * cells) if not empty else cells

    for i in range(cells):
        bx = body.left() + 3 + i * (cell_w + gap)
        cell_rect = QRectF(bx, c_top, cell_w, c_h)
        if empty or i >= filled_cells:
            emp = Qt.transparent if bit_depth == 1 else QColor("#DDDDDD") if bit_depth == 2 else QColor("#222222")
            painter.setBrush(emp)
            ep = Qt.black if bit_depth <= 2 else QColor("#444444")
            painter.setPen(QPen(ep, 0.5))
        else:
            painter.setBrush(fill)
            painter.setPen(QPen(Qt.black, 0.5) if bit_depth <= 2 else Qt.NoPen)
        #painter.drawRoundedRect(cell_rect, 2, 2)
        painter.drawRect(cell_rect)


def _draw_compass(painter: QPainter, rect: QRectF, fill_fraction: float,
                  color: QColor, empty: bool, bit_depth: int = 32) -> None:
    cx = rect.center().x()
    cy = rect.center().y()
    r = min(rect.width(), rect.height()) / 2 - 2

    bg, pen, fill, acc, tick = _theme(color, bit_depth)

    if bit_depth <= 2:
        painter.setPen(Qt.NoPen)
        painter.setBrush(bg)
        painter.drawEllipse(QPointF(cx, cy), r, r)
    else:
        bg_grad = QRadialGradient(cx, cy, r)
        bg_grad.setColorAt(0, QColor("#1A1A2E"))
        bg_grad.setColorAt(1, QColor("#0A0A14"))
        painter.setPen(Qt.NoPen)
        painter.setBrush(QBrush(bg_grad))
        painter.drawEllipse(QPointF(cx, cy), r, r)

    painter.setPen(QPen(pen, 2.5))
    painter.setBrush(Qt.NoBrush)
    painter.drawEllipse(QPointF(cx, cy), r, r)

    cardinals = ['N', 'E', 'S', 'W']
    font = QFont("Consolas", max(6, int(r * 0.18)))
    font.setBold(True)
    painter.setFont(font)
    fm = QFontMetrics(font)

    for i, label in enumerate(cardinals):
        ang = math.radians(i * 90 - 90)
        tr = r * 0.80
        lx = cx + tr * math.cos(ang)
        ly = cy + tr * math.sin(ang)
        painter.setPen(QPen(tick, 1.5))
        tk1x = cx + (r * 0.85) * math.cos(ang)
        tk1y = cy + (r * 0.85) * math.sin(ang)
        tk2x = cx + (r * 0.95) * math.cos(ang)
        tk2y = cy + (r * 0.95) * math.sin(ang)
        painter.drawLine(QPointF(tk1x, tk1y), QPointF(tk2x, tk2y))

        if bit_depth <= 2:
            c = Qt.black
        else:
            c = QColor("#FF3333") if label == 'N' else QColor("#CCCCCC")
        painter.setPen(c)
        bw = fm.horizontalAdvance(label)
        bh = fm.height()
        painter.drawText(QRectF(lx - bw / 2, ly - bh / 2, bw, bh),
                         Qt.AlignCenter, label)

    needle_angle = fill_fraction * 360.0 if not empty else 0.0
    ang_rad = math.radians(needle_angle - 90)
    nr = r * 0.62

    tip_red = QPointF(cx + nr * math.cos(ang_rad),
                      cy + nr * math.sin(ang_rad))
    tip_white = QPointF(cx - nr * math.cos(ang_rad),
                        cy - nr * math.sin(ang_rad))
    base_left = QPointF(
        cx + r * 0.06 * math.cos(ang_rad + math.pi / 2),
        cy + r * 0.06 * math.sin(ang_rad + math.pi / 2))
    base_right = QPointF(
        cx + r * 0.06 * math.cos(ang_rad - math.pi / 2),
        cy + r * 0.06 * math.sin(ang_rad - math.pi / 2))

    north_poly = QPolygonF([tip_red, base_left, base_right])
    
    painter.setPen(Qt.black if bit_depth <= 2 else Qt.NoPen)
    if bit_depth <= 2:
        painter.setBrush(fill)
    else:
        painter.setBrush(QColor("#FF3333"))
    painter.drawPolygon(north_poly)

    south_poly = QPolygonF([tip_white, base_left, base_right])
    painter.setBrush(Qt.white)
    painter.setPen(Qt.black if bit_depth <= 2 else Qt.NoPen)
    painter.drawPolygon(south_poly)

    painter.setBrush(Qt.black if bit_depth <= 2 else QColor("#CCCCCC"))
    painter.setPen(Qt.NoPen)
    painter.drawEllipse(QPointF(cx, cy), r * 0.07, r * 0.07)


# ─────────────────────────────────────────────
#  NEW ELEMENT DRAWING FUNCTIONS
# ─────────────────────────────────────────────

def _draw_led(painter: QPainter, rect: QRectF, fill_fraction: float,
              color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Round LED – dim when empty/off, glowing when on (fill_fraction > 0.5)."""
    cx, cy = rect.center().x(), rect.center().y()
    r = min(rect.width(), rect.height()) / 2 - 2
    on = (not empty) and fill_fraction > 0.5

    if bit_depth <= 2:
        painter.setPen(QPen(Qt.black, 1.5))
        painter.setBrush(Qt.black if on else Qt.white)
        painter.drawEllipse(QPointF(cx, cy), r, r)
    else:
        off_color = QColor("#2A2A2A")
        led_color = color if on else off_color
        grad = QRadialGradient(cx - r * 0.3, cy - r * 0.3, r * 1.2)
        grad.setColorAt(0.0, led_color.lighter(180) if on else QColor("#454545"))
        grad.setColorAt(0.6, led_color)
        grad.setColorAt(1.0, led_color.darker(150))
        painter.setPen(QPen(led_color.darker(200), 1.5))
        painter.setBrush(QBrush(grad))
        painter.drawEllipse(QPointF(cx, cy), r, r)
        if on:
            # halo
            halo = QColor(color)
            halo.setAlpha(60)
            painter.setPen(Qt.NoPen)
            painter.setBrush(halo)
            painter.drawEllipse(QPointF(cx, cy), r * 1.35, r * 1.35)
        # specular highlight
        painter.setPen(Qt.NoPen)
        hi = QColor(255, 255, 255, 80 if on else 30)
        painter.setBrush(hi)
        painter.drawEllipse(QPointF(cx - r * 0.28, cy - r * 0.28), r * 0.35, r * 0.35)


def _draw_warning_badge(painter: QPainter, rect: QRectF, fill_fraction: float,
                        color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Warning badge: triangle icon.  fill_fraction maps severity 0=OK 1=CRIT."""
    r = rect.adjusted(2, 2, -2, -2)
    if empty or fill_fraction < 0.25:
        badge_color = QColor("#00CC44") if bit_depth > 2 else QColor(Qt.black)
        icon = "✓"
    elif fill_fraction < 0.5:
        badge_color = QColor("#0088FF") if bit_depth > 2 else QColor(Qt.black)
        icon = "i"
    elif fill_fraction < 0.75:
        badge_color = QColor("#FFB300") if bit_depth > 2 else QColor(Qt.black)
        icon = "!"
    else:
        badge_color = QColor("#CC2222") if bit_depth > 2 else QColor(Qt.black)
        icon = "✕"

    if bit_depth <= 2:
        bg = QColor(Qt.white)
        fg = QColor(Qt.black)
        painter.setPen(QPen(fg, 1.5))
        painter.setBrush(bg)
        painter.drawRect(r)
        # Triangle outline
        mid_x = r.center().x()
        tri = QPolygonF([
            QPointF(mid_x, r.top() + 4),
            QPointF(r.left() + 4, r.bottom() - 4),
            QPointF(r.right() - 4, r.bottom() - 4),
        ])
        painter.drawPolygon(tri)
    else:
        bg = QColor("#1A1A2E")
        painter.setPen(Qt.NoPen)
        painter.setBrush(bg)
        painter.drawRoundedRect(r, 6, 6)
        painter.setPen(QPen(badge_color.darker(140), 1.5))
        painter.setBrush(badge_color)
        mid_x = r.center().x()
        tri = QPolygonF([
            QPointF(mid_x, r.top() + 6),
            QPointF(r.left() + 6, r.bottom() - 6),
            QPointF(r.right() - 6, r.bottom() - 6),
        ])
        painter.drawPolygon(tri)

    # Icon char
    font = QFont("Segoe UI", max(7, int(min(r.width(), r.height()) * 0.38)))
    font.setBold(True)
    painter.setFont(font)
    painter.setPen(Qt.white if bit_depth > 2 else Qt.black)
    painter.drawText(r, Qt.AlignCenter, icon)


def _draw_traffic_light(painter: QPainter, rect: QRectF, fill_fraction: float,
                        color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Three-bulb traffic light. fill_fraction: 0-0.33=green, 0.34-0.66=amber, else red."""
    r = rect.adjusted(2, 2, -2, -2)
    bg = Qt.white if bit_depth <= 2 else QColor("#111111")
    painter.setPen(QPen(Qt.black if bit_depth <= 2 else QColor("#444444"), 1.5))
    painter.setBrush(bg)
    painter.drawRoundedRect(r, 4, 4)

    pad = r.width() * 0.15
    bw = r.width() - 2 * pad
    br = bw / 2
    gap = (r.height() - 3 * bw) / 4

    colors_on  = [QColor("#CC2222"), QColor("#FFB300"), QColor("#00CC44")]
    colors_off = [QColor("#3A0808"), QColor("#3A2800"), QColor("#083A08")]
    if bit_depth <= 2:
        colors_on  = [QColor(Qt.black)] * 3
        colors_off = [QColor("#CCCCCC")] * 3

    if empty:
        active = -1
    elif fill_fraction >= 0.67:
        active = 0  # red
    elif fill_fraction >= 0.34:
        active = 1  # amber
    else:
        active = 2  # green

    for i in range(3):
        cx = r.center().x()
        cy = r.top() + gap + bw * 0.5 + i * (bw + gap)
        on = (i == active)
        if bit_depth > 2 and on:
            grad = QRadialGradient(cx - br * 0.25, cy - br * 0.25, br * 1.2)
            grad.setColorAt(0.0, colors_on[i].lighter(160))
            grad.setColorAt(0.7, colors_on[i])
            grad.setColorAt(1.0, colors_on[i].darker(140))
            painter.setBrush(QBrush(grad))
        else:
            painter.setBrush(colors_on[i] if on else colors_off[i])
        painter.setPen(Qt.NoPen)
        painter.drawEllipse(QPointF(cx, cy), br, br)


def _draw_toggle_switch(painter: QPainter, rect: QRectF, fill_fraction: float,
                        color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Rounded toggle switch.  fill_fraction > 0.5 = ON (right side)."""
    r = rect.adjusted(3, 3, -3, -3)
    h = r.height()
    radius = h / 2
    on = (not empty) and fill_fraction > 0.5

    if bit_depth <= 2:
        track_color = Qt.black if on else QColor("#CCCCCC")
        painter.setPen(QPen(Qt.black, 1.5))
    else:
        track_color = color if on else QColor("#444444")
        painter.setPen(Qt.NoPen)

    painter.setBrush(track_color)
    painter.drawRoundedRect(r, radius, radius)

    knob_d = h - 4
    knob_r = knob_d / 2
    if on:
        kx = r.right() - knob_r - 2
    else:
        kx = r.left() + knob_r + 2
    ky = r.center().y()

    painter.setPen(Qt.NoPen)
    knob_c = Qt.white if bit_depth > 2 else (QColor("#DDDDDD") if on else Qt.black)
    painter.setBrush(knob_c)
    painter.drawEllipse(QPointF(kx, ky), knob_r, knob_r)


def _draw_numeric_readout(painter: QPainter, rect: QRectF, fill_fraction: float,
                          color: QColor, empty: bool, bit_depth: int = 32,
                          unit: str = "", decimal_places: int = 1) -> None:
    """Dark numeric display showing fill_fraction as a formatted number (0–100 range)."""
    r = rect.adjusted(1, 1, -1, -1)
    bg = Qt.white if bit_depth <= 2 else QColor("#0D0D0D")
    pen_color = Qt.black if bit_depth <= 2 else QColor("#444444")
    painter.setPen(QPen(pen_color, 1.5))
    painter.setBrush(bg)
    painter.drawRect(r)

    if empty:
        txt = "----"
        txt_color = QColor("#444444") if bit_depth > 2 else QColor("#AAAAAA")
    else:
        val = fill_fraction * 100.0
        txt = f"{val:.{decimal_places}f}"
        if unit:
            txt += f" {unit}"
        txt_color = color if bit_depth > 2 else Qt.black

    font_size = max(8, int(r.height() * 0.45))
    font = QFont("Consolas", font_size)
    font.setBold(True)
    painter.setFont(font)
    painter.setPen(txt_color)
    painter.drawText(r, Qt.AlignCenter, txt)


def _draw_state_label(painter: QPainter, rect: QRectF, fill_fraction: float,
                      color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Discrete state badge.  fill_fraction maps to 4 states: STOP/IDLE/RUN/FAULT."""
    r = rect.adjusted(1, 1, -1, -1)
    states = [
        ("STOP",  QColor("#CC2222")),
        ("IDLE",  QColor("#888888")),
        ("RUN",   QColor("#00CC44")),
        ("FAULT", QColor("#FFB300")),
    ]
    # Always show a state — there is no meaningful "empty" mode for a state display.
    idx = min(3, int(fill_fraction * 4))
    state_txt, state_col = states[idx]

    if bit_depth <= 2:
        painter.setPen(QPen(Qt.black, 1.5))
        painter.setBrush(Qt.white)
        painter.drawRect(r)
        txt_color = Qt.black
    else:
        bg = QColor(state_col)
        bg.setAlpha(35)
        painter.setPen(QPen(state_col.darker(130), 1.5))
        painter.setBrush(bg)
        painter.drawRoundedRect(r, 4, 4)
        txt_color = state_col

    font_size = max(7, int(r.height() * 0.45))
    font = QFont("Segoe UI", font_size)
    font.setBold(True)
    painter.setFont(font)
    painter.setPen(txt_color if bit_depth > 2 else Qt.black)
    painter.drawText(r, Qt.AlignCenter, state_txt)


def _draw_trend_arrow(painter: QPainter, rect: QRectF, fill_fraction: float,
                      color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Trend arrow: up if >0.6, flat if 0.4–0.6, down if <0.4."""
    cx, cy = rect.center().x(), rect.center().y()
    r = rect.adjusted(4, 4, -4, -4)
    bg, pen, fill, acc, tick = _theme(color, bit_depth)

    painter.setPen(QPen(pen, 1.5))
    painter.setBrush(bg)
    painter.drawRect(rect.adjusted(1, 1, -1, -1))

    if empty:
        return

    if fill_fraction > 0.6:
        # up arrow
        pts = QPolygonF([
            QPointF(cx, r.top()),
            QPointF(r.right(), r.bottom()),
            QPointF(r.left(), r.bottom()),
        ])
        arrow_color = QColor("#00CC44") if bit_depth > 2 else Qt.black
    elif fill_fraction >= 0.4:
        # flat (right-pointing)
        mid_y = cy
        hw = r.width() / 2
        hh = r.height() * 0.22
        pts = QPolygonF([
            QPointF(cx + hw * 0.6, mid_y),
            QPointF(cx - hw * 0.2, mid_y - hh),
            QPointF(cx - hw * 0.2, mid_y + hh),
        ])
        arrow_color = QColor("#888888") if bit_depth > 2 else Qt.black
    else:
        # down arrow
        pts = QPolygonF([
            QPointF(cx, r.bottom()),
            QPointF(r.right(), r.top()),
            QPointF(r.left(), r.top()),
        ])
        arrow_color = QColor("#CC2222") if bit_depth > 2 else Qt.black

    painter.setPen(Qt.NoPen)
    painter.setBrush(arrow_color)
    painter.drawPolygon(pts)


def _draw_arc_gauge(painter: QPainter, rect: QRectF, fill_fraction: float,
                    color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Semi-circular arc gauge with colour zones."""
    cx = rect.center().x()
    cy = rect.bottom() - rect.height() * 0.05
    r_outer = min(rect.width() / 2, rect.height()) * 0.88
    arc_w = max(6.0, r_outer * 0.18)
    arc_r = r_outer - arc_w / 2
    arc_rect = QRectF(cx - arc_r, cy - arc_r, arc_r * 2, arc_r * 2)

    START_DEG = 180
    SPAN_DEG  = 180

    bg, pen, fill, acc, tick = _theme(color, bit_depth)

    # Draw only the upper half-disc so the bottom area stays empty
    half_disc = QPainterPath()
    full_arc_rect = QRectF(cx - r_outer, cy - r_outer, r_outer * 2, r_outer * 2)
    half_disc.moveTo(cx + r_outer, cy)
    half_disc.arcTo(full_arc_rect, 0, 180)   # CCW from right through top to left
    half_disc.closeSubpath()                  # straight line back = the diameter
    painter.setPen(Qt.NoPen)
    painter.setBrush(bg)
    painter.drawPath(half_disc)

    if bit_depth <= 2:
        track_pen = QPen(QColor("#CCCCCC"), arc_w, Qt.SolidLine, Qt.RoundCap) if bit_depth == 2 else Qt.NoPen
        fill_pen  = QPen(Qt.black, arc_w, Qt.SolidLine, Qt.RoundCap)
        needle_pen = QPen(Qt.black, 2, Qt.SolidLine, Qt.RoundCap)
    else:
        track_pen = QPen(QColor("#333333"), arc_w, Qt.SolidLine, Qt.RoundCap)
        fill_pen  = QPen(color, arc_w, Qt.SolidLine, Qt.RoundCap)
        needle_pen = QPen(Qt.white, 2, Qt.SolidLine, Qt.RoundCap)

    painter.setPen(track_pen)
    painter.setBrush(Qt.NoBrush)
    # Qt: positive span = CCW, negative = CW. We draw CW so the arc sits on the top half.
    painter.drawArc(arc_rect, int(START_DEG * 16), int(-SPAN_DEG * 16))

    if not empty and fill_fraction > 0:
        clamp = max(0.0, min(1.0, fill_fraction))
        painter.setPen(fill_pen)
        painter.drawArc(arc_rect, int(START_DEG * 16), int(-SPAN_DEG * clamp * 16))

        # Needle: 180° at 0%, 0° at 100% (sweeps CW = decreasing angle)
        needle_deg = START_DEG - SPAN_DEG * clamp
        needle_rad = math.radians(needle_deg)
        nr = r_outer * 0.68
        nx = cx + nr * math.cos(needle_rad)
        ny = cy - nr * math.sin(needle_rad)
        painter.setPen(needle_pen)
        painter.drawLine(QPointF(cx, cy), QPointF(nx, ny))

    # Ticks (CW from 9-o'clock to 3-o'clock)
    tick_pen = QPen(QColor("#666666") if bit_depth > 2 else Qt.black, 1)
    painter.setPen(tick_pen)
    for i in range(11):
        ang = math.radians(START_DEG - SPAN_DEG * i / 10)
        r1 = r_outer * 0.72
        r2 = r_outer * 0.84
        painter.drawLine(
            QPointF(cx + r1 * math.cos(ang), cy - r1 * math.sin(ang)),
            QPointF(cx + r2 * math.cos(ang), cy - r2 * math.sin(ang)),
        )

    painter.setPen(Qt.NoPen)
    cap = QColor("#888888") if bit_depth > 2 else Qt.black
    painter.setBrush(cap)
    painter.drawEllipse(QPointF(cx, cy), r_outer * 0.08, r_outer * 0.08)


def _draw_dual_bar(painter: QPainter, rect: QRectF, fill_fraction: float,
                   color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Two stacked horizontal bars: top=fill, bottom=complement."""
    r = rect.adjusted(1, 1, -1, -1)
    half_h = (r.height() - 4) / 2
    r_top = QRectF(r.left(), r.top(), r.width(), half_h)
    r_bot = QRectF(r.left(), r.top() + half_h + 4, r.width(), half_h)
    _draw_linear_h(painter, r_top, fill_fraction if not empty else 0.0, color, empty, bit_depth)
    comp = 1.0 - fill_fraction if not empty else 0.0
    _draw_linear_h(painter, r_bot, comp, color.lighter(130) if bit_depth > 2 else color, empty, bit_depth)


def _draw_thermometer(painter: QPainter, rect: QRectF, fill_fraction: float,
                      color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Classic thermometer: thin tube + bulb at base."""
    r = rect.adjusted(2, 2, -2, -2)
    cx = r.center().x()
    tube_w = max(6.0, r.width() * 0.28)
    bulb_r = max(tube_w * 0.9, r.width() * 0.35)
    tube_top  = r.top() + bulb_r
    tube_bot  = r.bottom() - bulb_r * 1.6
    tube_h    = tube_bot - tube_top
    bulb_cy   = r.bottom() - bulb_r * 0.6

    bg, pen, fill, acc, tick = _theme(color, bit_depth)
    tube_bg = Qt.white if bit_depth <= 2 else QColor("#1A1A1A")
    outline  = Qt.black if bit_depth <= 2 else color.darker(150)

    # Tube background
    tube_rect = QRectF(cx - tube_w / 2, tube_top, tube_w, tube_h)
    painter.setPen(QPen(outline, 1.5))
    painter.setBrush(tube_bg)
    painter.drawRect(tube_rect)

    # Fill inside tube
    if not empty and fill_fraction > 0:
        fill_h  = tube_h * fill_fraction
        fill_rect = QRectF(cx - tube_w / 2 + 2, tube_bot - fill_h,
                           tube_w - 4, fill_h)
        if bit_depth <= 2:
            painter.setPen(Qt.NoPen)
            painter.setBrush(fill)
        else:
            g = QLinearGradient(fill_rect.topLeft(), fill_rect.bottomLeft())
            g.setColorAt(0.0, color.lighter(130))
            g.setColorAt(1.0, color.darker(110))
            painter.setPen(Qt.NoPen)
            painter.setBrush(g)
        painter.drawRect(fill_rect)

    # Bulb
    painter.setPen(QPen(outline, 1.5))
    if bit_depth <= 2:
        painter.setBrush(fill)
    else:
        bg2 = QRadialGradient(cx - bulb_r * 0.25, bulb_cy - bulb_r * 0.25, bulb_r * 1.2)
        bg2.setColorAt(0.0, color.lighter(160))
        bg2.setColorAt(0.7, color)
        bg2.setColorAt(1.0, color.darker(150))
        painter.setBrush(bg2)
    painter.drawEllipse(QPointF(cx, bulb_cy), bulb_r, bulb_r)

    # Tick marks
    tick_pen = QPen(Qt.black if bit_depth <= 2 else QColor("#555555"), 0.8)
    painter.setPen(tick_pen)
    for i in range(1, 5):
        ty = tube_bot - tube_h * i / 5
        painter.drawLine(QPointF(cx + tube_w / 2, ty),
                         QPointF(cx + tube_w / 2 + 4, ty))


def _draw_pipe_h(painter: QPainter, rect: QRectF, fill_fraction: float,
                 color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Horizontal pipe segment."""
    r = rect.adjusted(1, 1, -1, -1)
    bg, pen, fill, acc, tick = _theme(color, bit_depth)
    tube_bg = Qt.white if bit_depth <= 2 else QColor("#1A1A2E")

    # Outer pipe
    painter.setPen(QPen(pen, 1.5))
    painter.setBrush(tube_bg)
    painter.drawRect(r)

    # Flow fill
    if not empty and fill_fraction > 0:
        inner = r.adjusted(2, 3, -2, -3)
        if bit_depth <= 2:
            painter.setPen(Qt.NoPen)
            painter.setBrush(fill)
        else:
            g = QLinearGradient(inner.topLeft(), inner.topRight())
            g.setColorAt(0.0, color.darker(120))
            g.setColorAt(0.5, color)
            g.setColorAt(1.0, color.darker(120))
            painter.setPen(Qt.NoPen)
            painter.setBrush(g)
        painter.drawRect(inner)

    # Pipe highlight / shading lines
    if bit_depth > 2:
        hi_pen = QPen(QColor(255, 255, 255, 35), 1)
        painter.setPen(hi_pen)
        painter.drawLine(QPointF(r.left() + 2, r.top() + 2),
                         QPointF(r.right() - 2, r.top() + 2))


def _draw_pipe_v(painter: QPainter, rect: QRectF, fill_fraction: float,
                 color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Vertical pipe segment (rotated version of pipe_h)."""
    r = rect.adjusted(1, 1, -1, -1)
    bg, pen, fill, acc, tick = _theme(color, bit_depth)
    tube_bg = Qt.white if bit_depth <= 2 else QColor("#1A1A2E")

    painter.setPen(QPen(pen, 1.5))
    painter.setBrush(tube_bg)
    painter.drawRect(r)

    if not empty and fill_fraction > 0:
        inner = r.adjusted(3, 2, -3, -2)
        fill_h = inner.height() * fill_fraction
        fill_rect = QRectF(inner.left(), inner.bottom() - fill_h, inner.width(), fill_h)
        if bit_depth <= 2:
            painter.setPen(Qt.NoPen)
            painter.setBrush(fill)
        else:
            g = QLinearGradient(inner.topLeft(), inner.topRight())
            g.setColorAt(0.0, color.darker(120))
            g.setColorAt(0.5, color)
            g.setColorAt(1.0, color.darker(120))
            painter.setPen(Qt.NoPen)
            painter.setBrush(g)
        painter.drawRect(fill_rect)

    if bit_depth > 2:
        hi_pen = QPen(QColor(255, 255, 255, 35), 1)
        painter.setPen(hi_pen)
        painter.drawLine(QPointF(r.left() + 2, r.top() + 2),
                         QPointF(r.left() + 2, r.bottom() - 2))


def _draw_valve(painter: QPainter, rect: QRectF, fill_fraction: float,
                color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Valve symbol: circle with a cross; fill_fraction > 0.5 = open (colored), else closed (gray)."""
    cx, cy = rect.center().x(), rect.center().y()
    r = min(rect.width(), rect.height()) / 2 - 3
    open_v = (not empty) and fill_fraction > 0.5

    body_color = color if open_v else (QColor("#555555") if bit_depth > 2 else QColor("#888888"))
    bg_color = QColor("#0D0D1A") if bit_depth > 2 else QColor("#FFFFFF")

    painter.setPen(QPen(body_color.darker(130) if bit_depth > 2 else Qt.black, 1.5))
    painter.setBrush(bg_color)
    painter.drawEllipse(QPointF(cx, cy), r, r)

    # Cross / bowtie
    quarter = r * 0.62
    painter.setPen(Qt.NoPen)
    painter.setBrush(body_color)
    bow_poly = QPolygonF([
        QPointF(cx - quarter, cy - quarter),
        QPointF(cx + quarter, cy + quarter),
        QPointF(cx + quarter, cy - quarter),
        QPointF(cx - quarter, cy + quarter),
    ])
    painter.drawPolygon(bow_poly)

    # Stem
    stem_w = max(3.0, r * 0.2)
    painter.setPen(QPen(body_color.darker(130) if bit_depth > 2 else Qt.black, stem_w))
    painter.drawLine(QPointF(cx, cy - r), QPointF(cx, cy - r * 1.55))
    painter.setBrush(body_color)
    painter.setPen(Qt.NoPen)
    painter.drawRect(QRectF(cx - stem_w * 1.5, cy - r * 1.65,
                            stem_w * 3, stem_w * 0.8))


def _draw_text_label(painter: QPainter, rect: QRectF, fill_fraction: float,
                     color: QColor, empty: bool, bit_depth: int = 32,
                     static_text: str = "Label", font_family: str = "Segoe UI") -> None:
    """Static text display."""
    r = rect.adjusted(1, 1, -1, -1)
    if bit_depth <= 2:
        painter.setPen(QPen(Qt.black, 1))
        painter.setBrush(Qt.white)
    else:
        painter.setPen(Qt.NoPen)
        painter.setBrush(QColor(0, 0, 0, 0))
    painter.drawRect(r)

    font_size = max(7, int(r.height() * 0.60))
    font = QFont(font_family if font_family else "Segoe UI", font_size)
    txt_color = color if bit_depth > 2 else Qt.black
    painter.setPen(txt_color)
    painter.setFont(font)
    txt = static_text if static_text else "Label"
    painter.drawText(r, Qt.AlignCenter | Qt.TextWordWrap, txt)


def _draw_rect_container(painter: QPainter, rect: QRectF, fill_fraction: float,
                         color: QColor, empty: bool, bit_depth: int = 32,
                         static_text: str = "") -> None:
    """Rectangle grouping container."""
    r = rect.adjusted(1, 1, -1, -1)
    if bit_depth <= 2:
        pen_color = Qt.black
        bg_color = Qt.transparent
    else:
        pen_color = color
        bg_color = QColor(0, 0, 0, 0)

    painter.setPen(QPen(pen_color, 1.5, Qt.DashLine))
    painter.setBrush(bg_color)
    painter.drawRoundedRect(r, 5, 5)

    if static_text:
        font_size = max(7, int(r.height() * 0.15))
        font = QFont("Segoe UI", font_size)
        painter.setFont(font)
        painter.setPen(color if bit_depth > 2 else Qt.black)
        label_r = QRectF(r.left() + 6, r.top() - font_size * 0.5,
                         r.width() - 12, font_size * 1.6)
        bg2 = QColor("#1E1E2E") if bit_depth > 2 else QColor(Qt.white)
        painter.fillRect(label_r, bg2)
        painter.drawText(label_r, Qt.AlignCenter, static_text)


def _draw_divider(painter: QPainter, rect: QRectF, fill_fraction: float,
                  color: QColor, empty: bool, bit_depth: int = 32) -> None:
    """Thin horizontal or vertical separator line."""
    cx, cy = rect.center().x(), rect.center().y()
    line_color = color if bit_depth > 2 else Qt.black
    # Decide orientation by aspect ratio
    if rect.width() >= rect.height():
        painter.setPen(QPen(line_color, max(1.0, rect.height() * 0.5)))
        painter.drawLine(QPointF(rect.left(), cy), QPointF(rect.right(), cy))
    else:
        painter.setPen(QPen(line_color, max(1.0, rect.width() * 0.5)))
        painter.drawLine(QPointF(cx, rect.top()), QPointF(cx, rect.bottom()))


# ─────────────────────────────────────────────
#  SHAPE DRAW FUNCTIONS
# ─────────────────────────────────────────────

def _draw_shape_rect(painter: QPainter, rect: QRectF, color: QColor,
                     stroke_color: QColor, stroke_width: float,
                     fill_enabled: bool, **_) -> None:
    inset = max(0.5, stroke_width) / 2
    r = rect.adjusted(inset, inset, -inset, -inset)
    painter.setPen(QPen(stroke_color, max(0.5, stroke_width)))
    painter.setBrush(QBrush(color) if fill_enabled else Qt.NoBrush)
    painter.drawRect(r)


def _draw_shape_ellipse(painter: QPainter, rect: QRectF, color: QColor,
                        stroke_color: QColor, stroke_width: float,
                        fill_enabled: bool, **_) -> None:
    inset = max(0.5, stroke_width) / 2
    r = rect.adjusted(inset, inset, -inset, -inset)
    painter.setPen(QPen(stroke_color, max(0.5, stroke_width)))
    painter.setBrush(QBrush(color) if fill_enabled else Qt.NoBrush)
    painter.drawEllipse(r)


def _draw_shape_triangle(painter: QPainter, rect: QRectF, color: QColor,
                         stroke_color: QColor, stroke_width: float,
                         fill_enabled: bool, **_) -> None:
    inset = max(0.5, stroke_width) / 2
    r = rect.adjusted(inset, inset, -inset, -inset)
    poly = QPolygonF([
        QPointF(r.left() + r.width() / 2, r.top()),
        QPointF(r.right(), r.bottom()),
        QPointF(r.left(), r.bottom()),
    ])
    painter.setPen(QPen(stroke_color, max(0.5, stroke_width)))
    painter.setBrush(QBrush(color) if fill_enabled else Qt.NoBrush)
    painter.drawPolygon(poly)


def _draw_shape_trapezoid(painter: QPainter, rect: QRectF, color: QColor,
                          stroke_color: QColor, stroke_width: float,
                          fill_enabled: bool, **_) -> None:
    inset = max(0.5, stroke_width) / 2
    r = rect.adjusted(inset, inset, -inset, -inset)
    cx = r.left() + r.width() / 2
    top_hw = r.width() * 0.325
    poly = QPolygonF([
        QPointF(cx - top_hw, r.top()),
        QPointF(cx + top_hw, r.top()),
        QPointF(r.right(), r.bottom()),
        QPointF(r.left(), r.bottom()),
    ])
    painter.setPen(QPen(stroke_color, max(0.5, stroke_width)))
    painter.setBrush(QBrush(color) if fill_enabled else Qt.NoBrush)
    painter.drawPolygon(poly)


def _draw_shape_arrow(painter: QPainter, rect: QRectF, color: QColor,
                      stroke_color: QColor, stroke_width: float,
                      fill_enabled: bool, **_) -> None:
    inset = max(0.5, stroke_width) / 2
    r = rect.adjusted(inset, inset, -inset, -inset)
    hx = r.left() + r.width() * 0.60
    ty = r.top()  + r.height() * 0.30
    by = r.bottom() - r.height() * 0.30
    my = r.top()  + r.height() / 2
    poly = QPolygonF([
        QPointF(r.left(), ty),
        QPointF(hx,       ty),
        QPointF(hx,       r.top()),
        QPointF(r.right(), my),
        QPointF(hx,       r.bottom()),
        QPointF(hx,       by),
        QPointF(r.left(), by),
    ])
    painter.setPen(QPen(stroke_color, max(0.5, stroke_width)))
    painter.setBrush(QBrush(color) if fill_enabled else Qt.NoBrush)
    painter.drawPolygon(poly)


def _draw_shape_line(painter: QPainter, rect: QRectF, stroke_color: QColor,
                     stroke_width: float, **_) -> None:
    pen = QPen(stroke_color, max(0.5, stroke_width))
    pen.setCapStyle(Qt.RoundCap)
    painter.setPen(pen)
    painter.setBrush(Qt.NoBrush)
    painter.drawLine(rect.topLeft(), rect.bottomRight())


def _draw_shape_bezier(painter: QPainter, rect: QRectF, color: QColor,
                       stroke_color: QColor, stroke_width: float,
                       fill_enabled: bool,
                       bezier_cp1: list, bezier_cp2: list, **_) -> None:
    p1  = QPointF(rect.left(),  rect.bottom())
    p4  = QPointF(rect.right(), rect.bottom())
    cp1 = QPointF(rect.left() + bezier_cp1[0] * rect.width(),
                  rect.top()  + bezier_cp1[1] * rect.height())
    cp2 = QPointF(rect.left() + bezier_cp2[0] * rect.width(),
                  rect.top()  + bezier_cp2[1] * rect.height())
    path = QPainterPath()
    path.moveTo(p1)
    path.cubicTo(cp1, cp2, p4)
    if fill_enabled:
        path.lineTo(rect.right(), rect.bottom())
        path.closeSubpath()
        painter.setBrush(QBrush(color))
    else:
        painter.setBrush(Qt.NoBrush)
    painter.setPen(QPen(stroke_color, max(0.5, stroke_width)))
    painter.drawPath(path)


# ─────────────────────────────────────────────
#  DISPATCH TABLE
# ─────────────────────────────────────────────

def draw_indicator(painter: QPainter, obj_type: str, rect: QRectF,
                   fill_fraction: float, color: QColor,
                   empty: bool = False, bit_depth: int = 32,
                   static_text: str = "", unit: str = "",
                   decimal_places: int = 1,
                   font_family: str = "Segoe UI",
                   stroke_color: QColor = None,
                   stroke_width: float = 2.0,
                   fill_enabled: bool = True,
                   bezier_cp1: list = None,
                   bezier_cp2: list = None) -> None:
    """Unified draw dispatcher."""
    if stroke_color is None:
        stroke_color = QColor("#FFFFFF")
    if bezier_cp1 is None:
        bezier_cp1 = [0.25, 0.0]
    if bezier_cp2 is None:
        bezier_cp2 = [0.75, 0.0]
    if bit_depth in (4, 7, 8, 16):  # match canvas background quantisation
        color = _quantize_color(color, bit_depth)
    fns = {
        "linear_h":       _draw_linear_h,
        "linear_v":       _draw_linear_v,
        "graph":          _draw_graph_indicator,
        "seven_seg":      _draw_seven_seg,
        "velocimeter":    _draw_velocimeter,
        "rotational":     _draw_rotational,
        "tank":           _draw_tank,
        "battery":        _draw_battery,
        "compass":        _draw_compass,
        # Status & Alerts
        "led":            _draw_led,
        "warning_badge":  _draw_warning_badge,
        "traffic_light":  _draw_traffic_light,
        "toggle_switch":  _draw_toggle_switch,
        # Data Readout
        "state_label":    _draw_state_label,
        "trend_arrow":    _draw_trend_arrow,
        # Gauges & Meters
        "arc_gauge":      _draw_arc_gauge,
        "dual_bar":       _draw_dual_bar,
        "thermometer":    _draw_thermometer,
        # Process & Flow
        "pipe_h":         _draw_pipe_h,
        "pipe_v":         _draw_pipe_v,
        "valve":          _draw_valve,
    }
    if obj_type == "seven_seg":
        _draw_seven_seg(painter, rect, fill_fraction, color, empty,
                        italic=False, hex_mode=False, bit_depth=bit_depth)
    elif obj_type == "numeric_readout":
        _draw_numeric_readout(painter, rect, fill_fraction, color, empty,
                              bit_depth=bit_depth, unit=unit, decimal_places=decimal_places)
    elif obj_type == "text_label":
        _draw_text_label(painter, rect, fill_fraction, color, empty,
                         bit_depth=bit_depth, static_text=static_text,
                         font_family=font_family)
    elif obj_type == "rect_container":
        _draw_rect_container(painter, rect, fill_fraction, color, empty,
                              bit_depth=bit_depth, static_text=static_text)
    elif obj_type == "divider":
        _draw_divider(painter, rect, fill_fraction, color, empty, bit_depth=bit_depth)
    elif obj_type == "shape_rect":
        _draw_shape_rect(painter, rect, color, stroke_color, stroke_width, fill_enabled)
    elif obj_type == "shape_ellipse":
        _draw_shape_ellipse(painter, rect, color, stroke_color, stroke_width, fill_enabled)
    elif obj_type == "shape_triangle":
        _draw_shape_triangle(painter, rect, color, stroke_color, stroke_width, fill_enabled)
    elif obj_type == "shape_trapezoid":
        _draw_shape_trapezoid(painter, rect, color, stroke_color, stroke_width, fill_enabled)
    elif obj_type == "shape_arrow":
        _draw_shape_arrow(painter, rect, color, stroke_color, stroke_width, fill_enabled)
    elif obj_type == "shape_line":
        _draw_shape_line(painter, rect, stroke_color, stroke_width)
    elif obj_type == "shape_bezier":
        _draw_shape_bezier(painter, rect, color, stroke_color, stroke_width, fill_enabled,
                           bezier_cp1, bezier_cp2)
    else:
        fn = fns.get(obj_type, _draw_linear_h)
        fn(painter, rect, fill_fraction, color, empty, bit_depth=bit_depth)


def render_to_pixmap(obj_type: str, width: int, height: int,
                     color: QColor, fill_fraction: float,
                     transparent_bg: bool = True,
                     static_text: str = "", unit: str = "",
                     decimal_places: int = 1, font_family: str = "Segoe UI",
                     stroke_color: QColor = None, stroke_width: float = 2.0,
                     fill_enabled: bool = True,
                     bezier_cp1: list = None, bezier_cp2: list = None) -> QPixmap:
    """Render an indicator to a QPixmap."""
    if stroke_color is None:
        stroke_color = QColor("#FFFFFF")
    if bezier_cp1 is None:
        bezier_cp1 = [0.25, 0.0]
    if bezier_cp2 is None:
        bezier_cp2 = [0.75, 0.0]
    pm = QPixmap(width, height)
    pm.fill(Qt.transparent if transparent_bg else Qt.black)
    painter = QPainter(pm)
    painter.setRenderHint(QPainter.Antialiasing)
    draw_indicator(painter, obj_type, QRectF(0, 0, width, height),
                   fill_fraction, color, fill_fraction == 0,
                   static_text=static_text, unit=unit, decimal_places=decimal_places,
                   font_family=font_family,
                   stroke_color=stroke_color, stroke_width=stroke_width,
                   fill_enabled=fill_enabled, bezier_cp1=bezier_cp1,
                   bezier_cp2=bezier_cp2)
    painter.end()
    return pm


def pixmap_to_bytes(pm: QPixmap, fmt: str = "32bit") -> bytes:
    """Convert QPixmap to PNG bytes in the requested bit depth."""
    img = pm.toImage()
    if fmt == "32bit":
        img = img.convertToFormat(QImage.Format_ARGB32)
    elif fmt == "16bit":
        img = img.convertToFormat(QImage.Format_RGB16)
    elif fmt == "bw":
        img = img.convertToFormat(QImage.Format_Mono)
    buf = io.BytesIO()
    img.save(buf, "PNG")  # type: ignore[arg-type] – actually accepts str
    return buf.getvalue()

# ─────────────────────────────────────────────
#  RISC-V TOOLCHAIN CHECKER
# ─────────────────────────────────────────────

_TOOLS_DIR  = os.path.join(_BUNDLE_DIR, "tools")
_SCENES_DIR = os.path.join(_DATA_DIR,   "scenes")

# ─────────────────────────────────────────────
#  TOOL SETTINGS  (persisted via QSettings)
# ─────────────────────────────────────────────
_APP_ORG  = "LacertaHMI"
_APP_NAME = "LacertaHMIDesigner"

def _qsettings() -> QSettings:
    return QSettings(_APP_ORG, _APP_NAME)

def get_riscv_path() -> str:
    """Return the user-configured RISC-V GCC executable path (empty = auto-detect)."""
    return _qsettings().value("riscv_gcc_path", "", type=str)

def set_riscv_path(path: str) -> None:
    s = _qsettings()
    s.setValue("riscv_gcc_path", path)
    s.sync()

def _riscv_gcc_exe() -> str:
    """Return path to riscv-none-elf-gcc.

    Priority order:
      1. User-configured path (Settings > Set Tool Paths)
      2. Local xpacks install  (tools/xpacks/…)
      3. System PATH
    """
    user = get_riscv_path()
    if user and os.path.isfile(user):
        return user
    local = os.path.join(
        _TOOLS_DIR, "xpacks", "xpack-dev-tools-riscv-none-elf-gcc",
        ".content", "bin",
        "riscv-none-elf-gcc.exe" if sys.platform == "win32" else "riscv-none-elf-gcc",
    )
    if os.path.isfile(local):
        return local
    return "riscv-none-elf-gcc"  # fall back to PATH


def _load_items_into_scene(scene: 'CanvasScene', data: list,
                           _parent_item=None, _existing: set = None):
    """Load indicator/group items from a JSON data list into a scene.
    Top-level call: skip items whose label already exists.
    Recursive (group children): always load, no duplicate check.
    """
    if _existing is None:
        _existing = {item.label for item in scene.items_only()}

    for entry in data:
        obj_type = entry.get("obj_type", "")

        if obj_type == "__group__":
            group = GroupItem()
            group._group_label = entry.get("label", group._group_label)
            group.setPos(entry.get("x", 0), entry.get("y", 0))
            group.layer = entry.get("layer", "default")
            if _parent_item is None:
                scene.addItem(group)
            else:
                group.setParentItem(_parent_item)
            _load_items_into_scene(scene, entry.get("children", []),
                                   _parent_item=group, _existing=_existing)
            continue

        # IndicatorItem - check duplicates only at the top level
        if _parent_item is None and entry.get("label") in _existing:
            continue

        color = QColor(entry.get("color", "#00CFFF"))
        item = IndicatorItem(
            obj_type,
            entry.get("x", 0), entry.get("y", 0),
            entry.get("width", 100), entry.get("height", 100),
            color=color,
            label=entry.get("label", ""),
            min_val=entry.get("min_val", 0.0),
            max_val=entry.get("max_val", 100.0),
        )
        item.seg_italic     = entry.get("seg_italic", False)
        item.seg_hex_mode   = entry.get("seg_hex_mode", False)
        item.static_text    = entry.get("static_text", "")
        item.font_family    = entry.get("font_family", "Segoe UI")
        item.unit_label     = entry.get("unit_label", "")
        item.decimal_places = entry.get("decimal_places", 1)
        item.stroke_color   = QColor(entry.get("stroke_color", "#FFFFFF"))
        item.stroke_width   = entry.get("stroke_width", 2.0)
        item.fill_enabled   = entry.get("fill_enabled", True)
        item.bezier_cp1     = entry.get("bezier_cp1", [0.25, 0.0])
        item.bezier_cp2     = entry.get("bezier_cp2", [0.75, 0.0])
        item.layer          = entry.get("layer", "default")
        item.layer_order    = entry.get("layer_order", 0)

        if _parent_item is None:
            scene.addItem(item)
            _existing.add(entry.get("label", ""))
        else:
            item.setParentItem(_parent_item)


def _parse_scene_file(data, json_path: str):
    """Return (items_list, bg_image_abs_path_or_None, delay_count_or_None, layers_list) from scene JSON."""
    if isinstance(data, list):
        return data, None, None, []
    items = data.get("items", [])
    bg_rel = data.get("bg_image")
    bg_abs = os.path.join(os.path.dirname(json_path), bg_rel) if bg_rel else None
    delay = data.get("delay_count")
    layers = data.get("layers", [])
    return items, bg_abs, delay, layers


# ─────────────────────────────────────────────
#  SETTINGS DIALOG
# ─────────────────────────────────────────────

class SettingsDialog(QDialog):
    """Settings > Set Tool Paths dialog."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Settings – Tool Paths")
        self.setMinimumWidth(540)

        layout = QVBoxLayout(self)

        form = QFormLayout()
        form.setLabelAlignment(Qt.AlignRight)

        self._riscv_edit = QLineEdit()
        self._riscv_edit.setPlaceholderText(
            "Leave blank to auto-detect (local xpacks → system PATH)"
        )
        self._riscv_edit.setText(get_riscv_path())
        browse_btn = QPushButton("Browse…")
        browse_btn.setFixedHeight(26)
        browse_btn.clicked.connect(self._browse_riscv)

        riscv_row = QHBoxLayout()
        riscv_row.setContentsMargins(0, 0, 0, 0)
        riscv_row.addWidget(self._riscv_edit)
        riscv_row.addWidget(browse_btn)

        riscv_container = QWidget()
        riscv_container.setLayout(riscv_row)

        form.addRow("riscv-none-elf-gcc:", riscv_container)
        layout.addLayout(form)

        note = QLabel(
            "Tip: this is the path to the <b>riscv-none-elf-gcc</b> executable "
            "inside the xpacks <code>.content/bin/</code> folder, or wherever "
            "the toolchain is installed."
        )
        note.setWordWrap(True)
        note.setStyleSheet("color:#888; font-size:11px; padding:4px 0;")
        layout.addWidget(note)

        buttons = QDialogButtonBox(
            QDialogButtonBox.Ok | QDialogButtonBox.Cancel
        )
        buttons.accepted.connect(self._accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)

    def _browse_riscv(self):
        exe_filter = (
            "Executables (*.exe)"
            if sys.platform == "win32"
            else "All files (*)"
        )
        path, _ = QFileDialog.getOpenFileName(
            self, "Locate riscv-none-elf-gcc", "", exe_filter
        )
        if path:
            self._riscv_edit.setText(path)

    def _accept(self):
        set_riscv_path(self._riscv_edit.text().strip())
        self.accept()


class RiscvCheckerThread(QThread):
    """Runs riscv-none-elf-gcc --version in a background thread."""
    done = Signal(bool, str)  # (found, version_line_or_error)

    def run(self):
        gcc = _riscv_gcc_exe()
        _flags = {"creationflags": subprocess.CREATE_NO_WINDOW} if sys.platform == "win32" else {}
        try:
            result = subprocess.run(
                [gcc, "--version"],
                capture_output=True, text=True, timeout=5, **_flags
            )
            version = result.stdout.splitlines()[0] if result.stdout else result.stderr.splitlines()[0]
            self.done.emit(result.returncode == 0, version)
        except FileNotFoundError:
            self.done.emit(False, f"Not found: {gcc}")
        except Exception as e:
            self.done.emit(False, str(e))

# ─────────────────────────────────────────────
#  SERIAL SCRIPT
# ─────────────────────────────────────────────
from PIL import Image
import serial
import numpy as np
import struct
import time
from random import randint
import serial.tools.list_ports

class SerialLoader():
    def __init__(self):
        self.current_serial_port = ""
        self.ser = 0
        self.default_array = []
        self.masks_path = "tools/masks/"
        self.instruction_path = ""
        self.bg_img_path = ""
        self.log_callback = None  # optional callable(msg, color) set by UploadWorker

    def set_serial_port(self):
        ...

    def serial_write_mem(self, addr, data):
        COMMAND = 1
        v = struct.pack('B', COMMAND)
        self.ser.write(v)
        v = struct.pack('B',addr)
        self.ser.write(v)
        v = struct.pack('I',data)
        self.ser.write(v)
        print("wrote " + "{:08X}".format(data) )

    def serial_read_mem(self, addr):
        COMMAND = 0
        v = struct.pack('B', COMMAND)
        self.ser.write(v)
        v = struct.pack('B',addr)
        self.ser.write(v)
        v = struct.pack('I',0)
        self.ser.write(v)
        while(self.ser.in_waiting < 4):
            pass
        val = self.ser.read(4)
        data_received = int.from_bytes(val, "little")
        print("read {:08X}".format(data_received))

    def read_character_by_character(self, filename):
        array_int = []
        with open(filename, 'r') as f:
            # Read the entire file content into a string
            content = f.read().replace('\n', '').replace('\r', '')
            for char in content:
                # Process each character
    #            print(char, end='')
                array_int.append(int(char))
        return array_int

    def set_characters(self):
        self.default_array = self.read_character_by_character(self.masks_path + "37_66_7seg_0.txt")
        self.default_array = self.default_array + self.read_character_by_character(self.masks_path + "37_66_7seg_1.txt")
        self.default_array = self.default_array + self.read_character_by_character(self.masks_path + "37_66_7seg_2.txt")
        self.default_array = self.default_array + self.read_character_by_character(self.masks_path + "37_66_7seg_3.txt")
        self.default_array = self.default_array + self.read_character_by_character(self.masks_path + "37_66_7seg_4.txt")
        self.default_array = self.default_array + self.read_character_by_character(self.masks_path + "37_66_7seg_5.txt")
        self.default_array = self.default_array + self.read_character_by_character(self.masks_path + "37_66_7seg_6.txt")
        self.default_array = self.default_array + self.read_character_by_character(self.masks_path + "37_66_7seg_7.txt")
        self.default_array = self.default_array + self.read_character_by_character(self.masks_path + "37_66_7seg_8.txt")
        self.default_array = self.default_array + self.read_character_by_character(self.masks_path + "37_66_7seg_9.txt")
        print(np.size(self.default_array))

    def set_paths(self, masks_path, instruction_path, bg_img_path):
        self.masks_path = masks_path
        self.instruction_path = instruction_path
        self.bg_img_path = bg_img_path

    def connect(self, port):
        try:
            self.ser = serial.Serial(port=port, baudrate=230400, timeout=1)
            self.current_serial_port = port
            print(f"Successfully connected to {port}")
        except Exception as e:
            print(f"Could not connect to {port}: {e}")

    def disconnect(self):
        try:
            if self.ser and self.ser.is_open:
                self.ser.close()
        except Exception:
            pass
        self.ser = 0
        self.current_serial_port = ""

    @property
    def is_connected(self) -> bool:
        try:
            return bool(self.ser) and self.ser.is_open
        except Exception:
            return False

    def serial_load_program(self):
        self.serial_write_mem(0x00, 0x0004B000) # set wpg starting address to 640x480
        self.serial_write_mem(0x01, np.size(self.default_array)) # set wpg burst length to 640x480
        self.serial_write_mem(0x02, 0x00000000) # set wpg busy to 1
        for val in self.default_array:
            self.serial_write_mem(0x06, val) # write mask to writing buffer
        instructions = []
        with open(self.instruction_path, 'r') as f:
            for line in f:
                # Strip whitespace (including newlines) from the line
                hex_string = line.strip()
                if hex_string:  # Ensure the line is not empty
                    try:
                        # Convert the hex string to an integer, specifying base 16
                        decimal_int = int(hex_string, 16)
                        instructions.append(decimal_int)
                    except ValueError:
                        print(f"Skipping invalid hex string: {hex_string}")
        UP_INSTR_OFFSET = 640*480+50_000 # this MUST be the same than rtl parameter
        self.serial_write_mem(0x00, 0x00000000 + UP_INSTR_OFFSET) # set wpg starting address to 0
        self.serial_write_mem(0x01, np.size(instructions)) # set wpg burst length to the number of instructions
        self.serial_write_mem(0x02, 0x00000000) # set wpg busy to 1
        cnt = 0
        for instr in instructions:
            print("writing instruction ", hex(instr))
            self.serial_write_mem(0x06, instr) # write instruction to writing buffer
            cnt = cnt + 1

        self.serial_write_mem(0x11, 0x00000000) # do a software reset to picorv32
        time.sleep(1)
        self.serial_write_mem(0x12, 0x00000000) # enable picorv32

    def serial_send_bg_img(self):
        self.serial_write_mem(0x00, 0x00000000) # set wpg starting address to 0
        self.serial_write_mem(0x01, 640*480)    # set wpg burst length to 640x480
        self.serial_write_mem(0x02, 0x00000000) # set wpg busy to 1
        bin_path = os.path.splitext(self.bg_img_path)[0] + ".bin"
        with Image.open(self.bg_img_path) as img:
            rgb_img = img.convert('RGB').resize((640, 480), Image.LANCZOS)
            with open(bin_path, 'w') as bf:
                for y in range(480):
                    for x in range(640):
                        r, g, b = rgb_img.getpixel((x, y))
                        # Pack as 1RRGGGBB: bit7=1, RR = top 2 bits of R, GGG = top 3 bits of G, BB = top 2 bits of B
                        packed = 0x80 | ((r >> 6) << 5) | ((g >> 5) << 2) | (b >> 6)
                        bf.write(f"{packed:08b}\n")
                        self.serial_write_mem(0x06, packed)
                        if self.log_callback:
                            self.log_callback(
                                f"[bg] pixel ({x:3d},{y:3d}) packed=0x{packed:02X}",
                                "#888888"
                            )

# ─────────────────────────────────────────────
#  UPLOAD WORKER
# ─────────────────────────────────────────────

class UploadWorker(QThread):
    """Runs serial upload steps in a background thread."""
    log      = Signal(str, str)   # (message, color)
    finished = Signal(bool, str)  # (success, error_message)

    def __init__(self, ser_loader, canvas_name, out_dir, has_bg, parent=None):
        super().__init__(parent)
        self._ser_loader  = ser_loader
        self._canvas_name = canvas_name
        self._out_dir     = out_dir
        self._has_bg      = has_bg

    def run(self):
        try:
            self.log.emit(f"Upload: sending characters for '{self._canvas_name}'…", "#56b6c2")
            self._ser_loader.set_characters()
            self.log.emit("set_characters() done.", "#56b6c2")

            if self._has_bg:
                self.log.emit("Sending background image (frame_empty.png)…", "#56b6c2")
                self._ser_loader.log_callback = self.log.emit
                self._ser_loader.serial_send_bg_img()
                self._ser_loader.log_callback = None
                self.log.emit("serial_send_bg_img() done.", "#56b6c2")

            self.log.emit("Loading program into FPGA…", "#56b6c2")
            self._ser_loader.serial_load_program()
            self.log.emit("serial_load_program() done.", "#98c379")
            self.finished.emit(True, "")
        except Exception as exc:
            self.finished.emit(False, str(exc))

# ─────────────────────────────────────────────
#  DIALOGS & CUSTOM WIDGETS
# ─────────────────────────────────────────────

class GridSpinBox(QSpinBox):
    """Custom spinbox that snaps to 10 on step."""
    def stepBy(self, steps: int):
        val = self.value()
        if steps > 0:
            rem = val % 10
            val = (val + (10 - rem)) if rem != 0 else (val + 10)
            steps -= 1
            val += steps * 10
            self.setValue(val)
        elif steps < 0:
            rem = val % 10
            val = (val - rem) if rem != 0 else (val - 10)
            steps += 1
            val += steps * 10
            self.setValue(val)

class ExportSceneDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Export Scene")
        layout = QVBoxLayout(self)

        form = QFormLayout()
        self.bit_combo = QComboBox()
        self.bit_combo.addItems(["32", "24", "16", "8", "4", "2", "1"])
        form.addRow("Bit Depth:", self.bit_combo)

        layout.addLayout(form)

        btns = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        btns.accepted.connect(self.accept)
        btns.rejected.connect(self.reject)
        layout.addWidget(btns)

    def values(self):
        return int(self.bit_combo.currentText())

# ─────────────────────────────────────────────
#  INDICATOR ITEM  (QGraphicsItem)
# ─────────────────────────────────────────────

class IndicatorItem(QGraphicsItem):
    """A draggable, resizable indicator placed on the canvas."""

    _id_counter = 0
    _type_counters = {}

    def __init__(self, obj_type: str, x: float, y: float,
                 width: float, height: float,
                 color: QColor = None,
                 label: str = "",
                 min_val: float = 0.0, max_val: float = 100.0):
        super().__init__()
        if color is None:
            color = QColor("#00CFFF")
        IndicatorItem._id_counter += 1
        self.item_id   = IndicatorItem._id_counter
        self.obj_type  = obj_type
        self.obj_w     = max(MIN_ITEM_SIZE, width)
        self.obj_h     = max(MIN_ITEM_SIZE, height)
        self.color     = color
        self.min_val   = min_val
        self.max_val   = max_val
        # Extended properties (7-seg)
        self.seg_italic   = False   # 7-seg: italic slant
        self.seg_hex_mode = False   # 7-seg: hex vs decimal
        # Extended properties (text-bearing types)
        self.static_text    = ""           # text_label / rect_container: display text
        self.font_family    = "Segoe UI"   # text_label: font family
        self.unit_label     = ""           # numeric_readout: unit suffix
        self.decimal_places = 1            # numeric_readout: decimal digits
        # Shape properties
        self.stroke_color   = QColor("#FFFFFF")
        self.stroke_width   = 2.0
        self.fill_enabled   = True
        self.bezier_cp1     = [0.25, 0.0]
        self.bezier_cp2     = [0.75, 0.0]
        # Layer
        self.layer          = "default"
        self.layer_order    = 0        # within-layer stacking order (higher = in front)
        # Preview state – set by PreviewPanel, never serialised
        self._preview_fraction: Optional[float] = None

        if label:
            self.label = label
        else:
            base = INDICATOR_LABELS.get(obj_type, obj_type).lower().replace(" ", "_")
            c = IndicatorItem._type_counters.get(obj_type, 0)
            self.label = f"{base}_{c}"
            IndicatorItem._type_counters[obj_type] = c + 1

        self.setPos(x, y)
        self.setFlags(
            QGraphicsItem.ItemIsMovable |
            QGraphicsItem.ItemIsSelectable |
            QGraphicsItem.ItemSendsGeometryChanges
        )
        self.setAcceptHoverEvents(True)

        self._resizing     = False
        self._resize_start = QPointF()
        self._orig_size    = (self.obj_w, self.obj_h)
        self._hover_handle = False

    @classmethod
    def _make_clone(cls, source: 'IndicatorItem', dx: float = 0, dy: float = 0) -> 'IndicatorItem':
        """Create a full copy of *source* offset by (dx, dy) with a fresh auto-label."""
        clone = cls(source.obj_type, source.x() + dx, source.y() + dy,
                    source.obj_w, source.obj_h, color=QColor(source.color))
        clone.min_val           = source.min_val
        clone.max_val           = source.max_val
        clone.seg_italic        = source.seg_italic
        clone.seg_hex_mode      = source.seg_hex_mode
        clone.static_text       = source.static_text
        clone.font_family       = source.font_family
        clone.unit_label        = source.unit_label
        clone.decimal_places    = source.decimal_places
        clone.stroke_color  = QColor(source.stroke_color)
        clone.stroke_width  = source.stroke_width
        clone.fill_enabled  = source.fill_enabled
        clone.bezier_cp1    = list(source.bezier_cp1)
        clone.bezier_cp2    = list(source.bezier_cp2)
        clone.layer         = source.layer
        clone._preview_fraction = source._preview_fraction
        return clone

    # ── bounding rect ──────────────────────────────────────────────────────
    def boundingRect(self) -> QRectF:
        return QRectF(0, 0, self.obj_w + HANDLE_SIZE,
                      self.obj_h + HANDLE_SIZE)

    def _indicator_rect(self) -> QRectF:
        return QRectF(0, 0, self.obj_w, self.obj_h)

    def _handle_rect(self) -> QRectF:
        return QRectF(self.obj_w - HANDLE_SIZE / 2,
                      self.obj_h - HANDLE_SIZE / 2,
                      HANDLE_SIZE, HANDLE_SIZE)

    # ── paint ──────────────────────────────────────────────────────────────
    def paint(self, painter: QPainter, option, widget=None) -> None:
        painter.setRenderHint(QPainter.Antialiasing)
        rect = self._indicator_rect()

        scene = self.scene()
        raw_bd = getattr(scene, "_bit_depth", 32)
        hw     = getattr(scene, "_hw_mode", False)
        bd     = getattr(scene, "effective_bit_depth", 32)

        # Compute the display colour: stage-1 depth quantization, then stage-2 HW RGB232
        disp_color = QColor(self.color)
        if raw_bd not in (32, 24):
            disp_color = _quantize_color(disp_color, raw_bd)
        if hw:
            disp_color = _quantize_color(disp_color, 7)

        if self._preview_fraction is not None:
            # Draw at the live preview value
            frac = self._preview_fraction
            if self.obj_type == "seven_seg":
                _draw_seven_seg(painter, rect, frac, disp_color, empty=False,
                                italic=self.seg_italic, hex_mode=self.seg_hex_mode, bit_depth=bd)
            else:
                draw_indicator(painter, self.obj_type, rect, frac, disp_color, empty=False,
                               bit_depth=bd, static_text=self.static_text,
                               unit=self.unit_label, decimal_places=self.decimal_places,
                               font_family=self.font_family,
                               stroke_color=self.stroke_color,
                               stroke_width=self.stroke_width,
                               fill_enabled=self.fill_enabled,
                               bezier_cp1=self.bezier_cp1,
                               bezier_cp2=self.bezier_cp2)
        else:
            # Normal empty display
            if self.obj_type == "seven_seg":
                _draw_seven_seg(painter, rect, 0.0, disp_color, empty=True,
                                italic=self.seg_italic, hex_mode=self.seg_hex_mode, bit_depth=bd)
            else:
                draw_indicator(painter, self.obj_type, rect, 0.0, disp_color, empty=True,
                               bit_depth=bd, static_text=self.static_text,
                               unit=self.unit_label, decimal_places=self.decimal_places,
                               font_family=self.font_family,
                               stroke_color=self.stroke_color,
                               stroke_width=self.stroke_width,
                               fill_enabled=self.fill_enabled,
                               bezier_cp1=self.bezier_cp1,
                               bezier_cp2=self.bezier_cp2)

        # Selection highlight
        if self.isSelected():
            pen = QPen(SELECTION_COLOR, 2, Qt.DashLine)
            painter.setPen(pen)
            painter.setBrush(Qt.NoBrush)
            painter.drawRect(rect.adjusted(-1, -1, 1, 1))

        # Label  (drawn outside bounding rect so it doesn't affect drag constraints)
        if self.label and not getattr(self.scene(), "_exporting", False):
            painter.setPen(QColor("#DDDDDD"))
            # Prevent negative point sizes, default to at least 1
            font = QFont("Segoe UI", max(1, 7))
            painter.setFont(font)
            # We use an un-clipped draw space pointing vertically down out of bounds
            painter.drawText(
                QRectF(0, self.obj_h + HANDLE_SIZE, self.obj_w, 20),
                Qt.AlignHCenter | Qt.AlignTop | Qt.TextDontClip, self.label)

        # Resize handle
        if not getattr(self.scene(), "_exporting", False):
            h_rect = self._handle_rect()
            handle_color = QColor("#FFD600") if self._hover_handle else QColor("#888888")
            painter.setBrush(handle_color)
            painter.setPen(Qt.NoPen)
            painter.drawRect(h_rect)

    # ── snapping & boundary constraint ────────────────────────────────────
    def itemChange(self, change, value):
        if change == QGraphicsItem.ItemPositionChange and self.scene():
            scene = self.scene()
            new_pos = value

            # Snap
            if scene.snap_enabled:
                g = scene.grid_size
                new_pos = QPointF(
                    round(new_pos.x() / g) * g,
                    round(new_pos.y() / g) * g,
                )

            # Constrain inside canvas only when not inside a group
            if self.parentItem() is None:
                cx1, cy1 = scene.canvas_x, scene.canvas_y
                cx2 = cx1 + scene.canvas_w - self.obj_w
                cy2 = cy1 + scene.canvas_h - self.obj_h
                new_pos = QPointF(
                    max(cx1, min(cx2, new_pos.x())),
                    max(cy1, min(cy2, new_pos.y())),
                )
            return new_pos

        if change == QGraphicsItem.ItemPositionHasChanged:
            if self.scene():
                self.scene().item_moved.emit(self)
        return super().itemChange(change, value)

    # ── hover ──────────────────────────────────────────────────────────────
    def hoverMoveEvent(self, event):
        self._hover_handle = self._handle_rect().contains(event.pos())
        self.update()
        super().hoverMoveEvent(event)

    def hoverLeaveEvent(self, event):
        self._hover_handle = False
        self.update()
        super().hoverLeaveEvent(event)

    # ── resize mouse events ────────────────────────────────────────────────
    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            if event.modifiers() & Qt.ControlModifier:
                # Clone original
                clone = IndicatorItem(self.obj_type, self.x(), self.y(), self.obj_w, self.obj_h)
                
                # Auto-generate a new suffix for the cloned label
                base = INDICATOR_LABELS.get(self.obj_type, self.obj_type).lower().replace(" ", "_")
                c = IndicatorItem._type_counters.get(self.obj_type, 0)
                clone.label = f"{base}_{c}"
                IndicatorItem._type_counters[self.obj_type] = c + 1
                
                clone.color = QColor(self.color)
                clone.min_val = self.min_val
                clone.max_val = self.max_val
                clone.seg_italic = self.seg_italic
                clone.seg_hex_mode = self.seg_hex_mode
                clone._preview_fraction = self._preview_fraction
                self.scene().addItem(clone)
                self.scene().item_added.emit()
                self.scene().clearSelection()
                self.setSelected(True)
                # Fall through to start drag on the original piece

            if self._handle_rect().contains(event.pos()):
                self._resizing     = True
                self._resize_start = event.scenePos()
                self._orig_size    = (self.obj_w, self.obj_h)
                event.accept()
                return
        super().mousePressEvent(event)

    def mouseMoveEvent(self, event):
        if self._resizing:
            delta = event.scenePos() - self._resize_start
            new_w = max(MIN_ITEM_SIZE, self._orig_size[0] + delta.x())
            new_h = max(MIN_ITEM_SIZE, self._orig_size[1] + delta.y())
            # Snap sizing
            if self.scene() and self.scene().snap_enabled:
                g = self.scene().grid_size
                new_w = round(new_w / g) * g
                new_h = round(new_h / g) * g
                new_w = max(MIN_ITEM_SIZE, new_w)
                new_h = max(MIN_ITEM_SIZE, new_h)

            self.prepareGeometryChange()
            self.obj_w = new_w
            self.obj_h = new_h
            if self.scene():
                self.scene().item_resized.emit(self)
            event.accept()
            return
        super().mouseMoveEvent(event)

    def mouseReleaseEvent(self, event):
        if self._resizing:
            self._resizing = False
            event.accept()
            return
        if event.button() == Qt.LeftButton:
            scene = self.scene()
            if scene and scene._drag_active:
                if scene._copy_mode:
                    scene._finalize_copy_drag()
                else:
                    scene._drag_active  = False
                    scene._drag_origins = {}
        super().mouseReleaseEvent(event)

    # ── st_pix convenience ────────────────────────────────────────────────
    def st_pix(self):
        """Top-left position relative to canvas origin."""
        if self.scene():
            scene = self.scene()
            return (int(self.x() - scene.canvas_x),
                    int(self.y() - scene.canvas_y))
        return (int(self.x()), int(self.y()))

    # ── image generation ─────────────────────────────────────────────────
    def generate_images(self, fmt: str = "32bit"):
        """Return (empty_png_bytes, filled_png_bytes)."""
        w, h = int(self.obj_w), int(self.obj_h)
        empty_pm  = render_to_pixmap(self.obj_type, w, h, self.color, 0.0)
        filled_pm = render_to_pixmap(self.obj_type, w, h, self.color, 1.0)
        return (pixmap_to_bytes(empty_pm, fmt),
                pixmap_to_bytes(filled_pm, fmt))

    # ── serialisation ─────────────────────────────────────────────────────
    def to_dict(self) -> dict:
        px, py = self.st_pix()
        return {
            "id":         self.item_id,
            "obj_type":   self.obj_type,
            "obj_width":  int(self.obj_w),
            "obj_height": int(self.obj_h),
            "st_pix":     [px, py],
            "min_val":    self.min_val,
            "max_val":    self.max_val,
            "color":      self.color.name(),
            "label":      self.label,
        }


# ─────────────────────────────────────────────
#  GROUP ITEM
# ─────────────────────────────────────────────

class GroupItem(QGraphicsItem):
    """Container that groups IndicatorItems / nested GroupItems and moves them as one."""

    _counter = 0

    def __init__(self, parent=None):
        super().__init__(parent)
        GroupItem._counter += 1
        self._group_label = f"group_{GroupItem._counter}"
        self._hovered = False
        self.layer    = "default"
        self.setFlags(
            QGraphicsItem.ItemIsMovable |
            QGraphicsItem.ItemIsSelectable |
            QGraphicsItem.ItemSendsGeometryChanges
        )
        self.setAcceptHoverEvents(True)

    # Required abstract method
    def boundingRect(self) -> QRectF:
        # Union of all children rects in local space, with a small margin
        cr = self.childrenBoundingRect()
        return cr.adjusted(-4, -4, 4, 4) if not cr.isNull() else QRectF(-4, -4, 8, 8)

    def paint(self, painter: QPainter, option, widget=None) -> None:
        br = self.boundingRect()
        if self.isSelected():
            pen = QPen(QColor("#61AFEF"), 1.5, Qt.DashLine)
        elif self._hovered:
            pen = QPen(QColor("#999999"), 1.0, Qt.DashLine)
        else:
            pen = QPen(QColor("#555555"), 1.0, Qt.DashLine)
        painter.setPen(pen)
        painter.setBrush(Qt.NoBrush)
        r = br.adjusted(1, 1, -1, -1)
        painter.drawRect(r)
        # Small badge in top-left corner
        painter.setFont(QFont("Segoe UI", 7))
        painter.setPen(QColor("#888888"))
        painter.drawText(r.adjusted(3, 2, 0, 0), Qt.AlignTop | Qt.AlignLeft, "⊞")

    def hoverEnterEvent(self, event):
        self._hovered = True
        self.update()
        super().hoverEnterEvent(event)

    def hoverLeaveEvent(self, event):
        self._hovered = False
        self.update()
        super().hoverLeaveEvent(event)

    def itemChange(self, change, value):
        # Apply grid snap, but no canvas-edge constraint at group level
        if (change == QGraphicsItem.ItemPositionChange
                and self.scene() and self.parentItem() is None):
            scene = self.scene()
            if scene.snap_enabled:
                g = scene.grid_size
                value = QPointF(
                    round(value.x() / g) * g,
                    round(value.y() / g) * g,
                )
        return super().itemChange(change, value)

    def all_indicators(self) -> list:
        """Recursively return every IndicatorItem inside this group."""
        result = []
        for child in self.childItems():
            if isinstance(child, IndicatorItem):
                result.append(child)
            elif isinstance(child, GroupItem):
                result.extend(child.all_indicators())
        return result


def _serialize_item(item) -> dict:
    """Recursively turn an IndicatorItem or GroupItem into a JSON-safe dict."""
    if isinstance(item, GroupItem):
        return {
            "obj_type": "__group__",
            "label":    item._group_label,
            "x":        item.x(),
            "y":        item.y(),
            "layer":    item.layer,
            "children": [
                _serialize_item(c) for c in item.childItems()
                if isinstance(c, (IndicatorItem, GroupItem))
            ],
        }
    # IndicatorItem
    return {
        "obj_type":       item.obj_type,
        "label":          item.label,
        "x":              item.x(),
        "y":              item.y(),
        "width":          item.obj_w,
        "height":         item.obj_h,
        "color":          item.color.name(),
        "min_val":        item.min_val,
        "max_val":        item.max_val,
        "seg_italic":     item.seg_italic,
        "seg_hex_mode":   item.seg_hex_mode,
        "static_text":    item.static_text,
        "font_family":    item.font_family,
        "unit_label":     item.unit_label,
        "decimal_places": item.decimal_places,
        "stroke_color":   item.stroke_color.name(),
        "stroke_width":   item.stroke_width,
        "fill_enabled":   item.fill_enabled,
        "bezier_cp1":     item.bezier_cp1,
        "bezier_cp2":     item.bezier_cp2,
        "layer":          item.layer,
        "layer_order":    getattr(item, 'layer_order', 0),
    }


# ─────────────────────────────────────────────
#  LAYER
# ─────────────────────────────────────────────

class Layer:
    """Runtime layer record kept in CanvasScene.layers."""
    def __init__(self, name: str, visible: bool = True):
        self.name    = name
        self.visible = visible


# ─────────────────────────────────────────────
#  CANVAS SCENE
# ─────────────────────────────────────────────

class CanvasScene(QGraphicsScene):
    item_selected   = Signal(object)   # IndicatorItem | None
    item_moved      = Signal(object)   # IndicatorItem
    item_resized    = Signal(object)   # IndicatorItem
    item_added      = Signal()
    item_removed    = Signal()
    layers_changed  = Signal()

    def __init__(self, canvas_w: int = DEFAULT_CANVAS_W,
                 canvas_h: int = DEFAULT_CANVAS_H, parent=None):
        super().__init__(parent)
        self.canvas_w    = canvas_w
        self.canvas_h    = canvas_h
        self.canvas_x    = 100.0
        self.canvas_y    = 100.0
        self.grid_size   = DEFAULT_GRID_SIZE
        self.snap_enabled = True
        self.show_grid   = True
        self._bit_depth  = 32
        self._hw_mode   = False
        # Layers (index 0 = bottom/back, last = top/front)
        self.layers: list = [Layer("default")]
        self.active_layer: str = "default"
        # Cascade offset so palette-added items don't all stack at (120,120)
        self._cascade_count = 0
        # Python-level refs to keep QGraphicsItem wrappers alive (PySide6 GC fix)
        self._py_items: list = []

        # drag-copy state (mid-drag Ctrl ghost-copy)
        self._drag_active  = False
        self._drag_origins: dict = {}  # IndicatorItem → QPointF at drag start
        self._ghost_items:  list = []  # semi-transparent placeholder IndicatorItems
        self._copy_mode    = False

        pad = 200
        self.setSceneRect(0, 0,
                          canvas_w + 2 * (self.canvas_x + pad),
                          canvas_h + 2 * (self.canvas_y + pad))
        self.setBackgroundBrush(QBrush(SCENE_BG))

        self.bg_color = QColor(CANVAS_BG)
        self.bg_image: Optional[QPixmap] = None
        self._depth_bg_cache: Optional[QPixmap] = None  # quantized bg, rebuilt on depth/bg change
        self._depth_bg_cache_bd: int = 0

        self._canvas_rect = QGraphicsRectItem(
            self.canvas_x, self.canvas_y, canvas_w, canvas_h)
        self._canvas_rect.setBrush(Qt.NoBrush)
        self._canvas_rect.setPen(QPen(QColor("#AAAAAA"), 1))
        self._canvas_rect.setZValue(-10)
        self.addItem(self._canvas_rect)

        self.selectionChanged.connect(self._on_selection_changed)

    def _activate_copy_mode(self):
        """Called when Ctrl is pressed mid-drag.
        Places a semi-transparent ghost at each item's drag-start position.
        The dragged items become the copies; ghosts show where originals will be restored.
        """
        if not self._drag_active or self._copy_mode:
            return
        self._copy_mode = True
        for item, origin in self._drag_origins.items():
            ghost = IndicatorItem(item.obj_type, origin.x(), origin.y(),
                                  item.obj_w, item.obj_h, color=QColor(item.color),
                                  label=item.label)
            ghost.seg_italic        = item.seg_italic
            ghost.seg_hex_mode      = item.seg_hex_mode
            ghost._preview_fraction = item._preview_fraction
            ghost.stroke_color      = QColor(item.stroke_color)
            ghost.stroke_width      = item.stroke_width
            ghost.fill_enabled      = item.fill_enabled
            ghost.bezier_cp1        = list(item.bezier_cp1)
            ghost.bezier_cp2        = list(item.bezier_cp2)
            ghost.layer             = item.layer
            ghost.setOpacity(0.30)
            ghost.setFlag(QGraphicsItem.ItemIsMovable,    False)
            ghost.setFlag(QGraphicsItem.ItemIsSelectable, False)
            ghost.setAcceptHoverEvents(False)
            self.addItem(ghost)
            self._ghost_items.append(ghost)

    def _finalize_copy_drag(self):
        """Called on mouse release in copy mode.
        Dragged items stay at their new positions (they are the copies).
        New items are created at each item's drag-start position (the originals).
        """
        for ghost in self._ghost_items:
            self.removeItem(ghost)
        self._ghost_items.clear()
        for item, origin in self._drag_origins.items():
            original = IndicatorItem._make_clone(item)
            original.setPos(origin)
            self.addItem(original)
        self.item_added.emit()
        self._copy_mode    = False
        self._drag_active  = False
        self._drag_origins = {}

    def resize_canvas(self, w: int, h: int) -> None:
        self.canvas_w = w
        self.canvas_h = h
        self._canvas_rect.setRect(self.canvas_x, self.canvas_y, w, h)
        pad = 200
        self.setSceneRect(0, 0,
                          w + 2 * (self.canvas_x + pad),
                          h + 2 * (self.canvas_y + pad))

    def set_bg_image(self, pixmap: Optional['QPixmap']) -> None:
        """Set (or clear) the background image for the canvas."""
        self.bg_image = pixmap
        self._depth_bg_cache = None
        self._rebuild_depth_bg()
        self.invalidate(self.sceneRect(), QGraphicsScene.BackgroundLayer)

    def resize_canvas(self, w: int, h: int) -> None:
        self.canvas_w = w
        self.canvas_h = h
        self._canvas_rect.setRect(self.canvas_x, self.canvas_y, w, h)
        pad = 200
        self.setSceneRect(0, 0,
                          w + 2 * (self.canvas_x + pad),
                          h + 2 * (self.canvas_y + pad))
        self._depth_bg_cache = None
        self._rebuild_depth_bg()

    @property
    def bit_depth(self) -> int:
        return self._bit_depth

    @bit_depth.setter
    def bit_depth(self, value: int) -> None:
        self._bit_depth = value
        self._depth_bg_cache = None
        self._rebuild_depth_bg()
        self.invalidate(self.sceneRect())
        for item in self.items():
            item.update()

    @property
    def hw_mode(self) -> bool:
        return self._hw_mode

    @hw_mode.setter
    def hw_mode(self, value: bool) -> None:
        self._hw_mode = value
        self._depth_bg_cache = None
        self._rebuild_depth_bg()
        # Invalidate ALL layers (background + item cache) and force repaint of every item
        self.invalidate(self.sceneRect())
        for item in self.items():
            item.update()

    @property
    def effective_bit_depth(self) -> int:
        """The bit depth passed to draw functions: 7 (RGB232) when HW mode is on."""
        return 7 if self._hw_mode else self._bit_depth

    def _rebuild_depth_bg(self) -> None:
        """Pre-compute a quantized background QPixmap.
        Stage 1: selected bit depth (if < 32/24). Stage 2: RGB232 if HW mode on.
        Called once when depth/hw_mode/bg_color/bg_image changes.
        """
        bd = self._bit_depth
        if bd in (32, 24) and not self._hw_mode:
            self._depth_bg_cache = None   # full quality – use raw painting
            self._depth_bg_cache_bd = bd
            return
        w, h = int(self.canvas_w), int(self.canvas_h)
        img = QImage(w, h, QImage.Format_RGB888)
        img.fill(self.bg_color)
        if self.bg_image is not None and not self.bg_image.isNull():
            p = QPainter(img)
            p.drawPixmap(QRect(0, 0, w, h), self.bg_image, self.bg_image.rect())
            p.end()
        # Stage 1: depth quantization
        if bd not in (32, 24):
            img = _quantize_qimage(img, bd)
        # Stage 2: HW RGB232 quantization
        if self._hw_mode:
            img = _quantize_qimage(img, 7)
        self._depth_bg_cache = QPixmap.fromImage(img)
        self._depth_bg_cache_bd = bd

    def drawBackground(self, painter: QPainter, rect: QRectF) -> None:
        super().drawBackground(painter, rect)

        canvas_rect = QRectF(self.canvas_x, self.canvas_y, self.canvas_w, self.canvas_h)

        # 1. Draw canvas background – use pre-quantized pixmap when available
        if (self._depth_bg_cache is not None
                and self._depth_bg_cache_bd == self._bit_depth):
            painter.drawPixmap(canvas_rect.toRect(), self._depth_bg_cache,
                               self._depth_bg_cache.rect())
        else:
            painter.fillRect(canvas_rect, self.bg_color)
            if self.bg_image is not None and not self.bg_image.isNull():
                painter.drawPixmap(canvas_rect.toRect(),
                                   self.bg_image,
                                   self.bg_image.rect())

        # 2. Determine contrast-friendly grid color based on background lightness
        bg_rgb = self.bg_color.getRgb()
        lum = 0.299 * bg_rgb[0] + 0.587 * bg_rgb[1] + 0.114 * bg_rgb[2]
        grid_color = QColor("#D0D0D0") if lum < 128 else QColor("#555555")

        if not self.show_grid or getattr(self, "_exporting", False):
            return
        painter.save()
        g = self.grid_size
        left   = self.canvas_x
        top    = self.canvas_y
        right  = left + self.canvas_w
        bottom = top  + self.canvas_h

        # Use a solid thin pen – dotted pens are often invisible at small zoom
        painter.setPen(QPen(grid_color, 0.5, Qt.SolidLine))
        x = left
        while x <= right + 0.01:
            painter.drawLine(QPointF(x, top), QPointF(x, bottom))
            x += g
        y = top
        while y <= bottom + 0.01:
            painter.drawLine(QPointF(left, y), QPointF(right, y))
            y += g
        painter.restore()

    def _on_selection_changed(self) -> None:
        items = self.selectedItems()
        # Emit the first IndicatorItem, or None when only groups (or nothing) selected
        sel = next((i for i in items if isinstance(i, IndicatorItem)), None)
        self.item_selected.emit(sel)

    def addItem(self, item):
        super().addItem(item)
        # Keep a Python-level reference to prevent PySide6 GC from destroying
        # QGraphicsItem subclass wrappers while they live in the scene.
        if isinstance(item, (IndicatorItem, GroupItem)):
            self._py_items.append(item)

    def removeItem(self, item):
        super().removeItem(item)
        try:
            self._py_items.remove(item)
        except ValueError:
            pass

    def add_indicator(self, obj_type: str, pos=None):
        w, h = DEFAULT_SIZES.get(obj_type, (100, 100))
        if pos is not None:
            x, y = pos.x(), pos.y()
        else:
            # Cascade so palette-dropped items don't all stack at the same spot
            step = self.grid_size
            max_steps = max(1, int(min(self.canvas_w, self.canvas_h) * 0.4 / step))
            offset = (self._cascade_count % max_steps) * step
            x = self.canvas_x + 20 + offset
            y = self.canvas_y + 20 + offset
            self._cascade_count += 1
        x = max(self.canvas_x, min(self.canvas_x + self.canvas_w - w, x))
        y = max(self.canvas_y, min(self.canvas_y + self.canvas_h - h, y))
        item = IndicatorItem(obj_type, x, y, w, h)
        self.addItem(item)
        lyr = self.get_layer(self.active_layer)
        if lyr:
            item.layer = self.active_layer
            item.setVisible(lyr.visible)
            idx = next((i for i, l in enumerate(self.layers) if l.name == self.active_layer), 0)
            # Assign next within-layer order so new items stack in front of existing ones
            existing_orders = [
                getattr(i, 'layer_order', 0) for i in self.items()
                if isinstance(i, (IndicatorItem, GroupItem))
                and getattr(i, 'layer', 'default') == self.active_layer
                and i is not item
            ]
            item.layer_order = (max(existing_orders) + 1) if existing_orders else 0
            item.setZValue(float(idx * 10000 + item.layer_order))
        self.item_added.emit()
        return item

    def remove_item(self, item):
        self.removeItem(item)
        self.item_removed.emit()

    def items_only(self) -> list:
        """All IndicatorItems in the scene (including those inside groups)."""
        return [i for i in self.items() if isinstance(i, IndicatorItem)]

    def top_level_items(self) -> list:
        """Top-level IndicatorItems and GroupItems (no parent item)."""
        return [i for i in self.items()
                if isinstance(i, (IndicatorItem, GroupItem))
                and i.parentItem() is None]

    # ── layer management ───────────────────────────────────────────────────
    def get_layer(self, name: str):
        return next((l for l in self.layers if l.name == name), None)

    def add_layer(self, name: str) -> bool:
        name = name.strip()
        if not name or self.get_layer(name):
            return False
        self.layers.append(Layer(name))
        self.layers_changed.emit()
        return True

    def remove_layer(self, name: str) -> bool:
        if name == "default":
            return False
        # Move items on this layer to default
        for item in self.items():
            if isinstance(item, (IndicatorItem, GroupItem)):
                if getattr(item, 'layer', 'default') == name:
                    item.layer = "default"
        self.layers = [l for l in self.layers if l.name != name]
        if self.active_layer == name:
            self.active_layer = "default"
        self._sync_layer_z()
        self.layers_changed.emit()
        return True

    def rename_layer(self, old_name: str, new_name: str) -> bool:
        if old_name == "default":
            return False
        new_name = new_name.strip()
        if not new_name or self.get_layer(new_name):
            return False
        lyr = self.get_layer(old_name)
        if not lyr:
            return False
        lyr.name = new_name
        if self.active_layer == old_name:
            self.active_layer = new_name
        for item in self.items():
            if isinstance(item, (IndicatorItem, GroupItem)):
                if getattr(item, 'layer', 'default') == old_name:
                    item.layer = new_name
        self.layers_changed.emit()
        return True

    def set_layer_visible(self, name: str, visible: bool):
        lyr = self.get_layer(name)
        if lyr:
            lyr.visible = visible
            self._sync_layer_visibility()
            self.layers_changed.emit()

    def move_layer(self, name: str, direction: int):
        """Move layer up (+1) or down (-1)."""
        idx = next((i for i, l in enumerate(self.layers) if l.name == name), -1)
        if idx < 0:
            return
        new_idx = idx + direction
        if new_idx < 0 or new_idx >= len(self.layers):
            return
        self.layers[idx], self.layers[new_idx] = self.layers[new_idx], self.layers[idx]
        self._sync_layer_z()
        self.layers_changed.emit()

    def set_item_layer(self, item, name: str):
        lyr = self.get_layer(name)
        if not lyr:
            return
        item.layer = name
        item.setVisible(lyr.visible)
        idx = next((i for i, l in enumerate(self.layers) if l.name == name), 0)
        sub = getattr(item, 'layer_order', 0)
        item.setZValue(float(idx * 10000 + sub))
        self.layers_changed.emit()

    def _sync_layer_visibility(self):
        vis = {l.name: l.visible for l in self.layers}
        for item in self.items():
            if isinstance(item, (IndicatorItem, GroupItem)):
                lname = getattr(item, 'layer', 'default')
                item.setVisible(vis.get(lname, True))

    def _sync_layer_z(self):
        z_map = {l.name: i for i, l in enumerate(self.layers)}
        for item in self.items():
            if isinstance(item, (IndicatorItem, GroupItem)) and item.parentItem() is None:
                lname = getattr(item, 'layer', 'default')
                li = z_map.get(lname, 0)
                sub = getattr(item, 'layer_order', 0)
                item.setZValue(float(li * 10000 + sub))

    # ── within-layer ordering ───────────────────────────────────────────────
    def move_item_in_layer(self, item, action: str):
        """action: 'up', 'down', 'front', 'back'"""
        lname = getattr(item, 'layer', 'default')
        peers = sorted(
            [i for i in self.items()
             if isinstance(i, (IndicatorItem, GroupItem))
             and i.parentItem() is None
             and getattr(i, 'layer', 'default') == lname],
            key=lambda i: getattr(i, 'layer_order', 0)
        )
        if item not in peers:
            return
        idx = peers.index(item)
        if action == 'up' and idx < len(peers) - 1:
            peers[idx].layer_order, peers[idx + 1].layer_order = \
                peers[idx + 1].layer_order, peers[idx].layer_order
        elif action == 'down' and idx > 0:
            peers[idx].layer_order, peers[idx - 1].layer_order = \
                peers[idx - 1].layer_order, peers[idx].layer_order
        elif action == 'front':
            item.layer_order = (max(getattr(i, 'layer_order', 0) for i in peers) + 1)
        elif action == 'back':
            item.layer_order = (min(getattr(i, 'layer_order', 0) for i in peers) - 1)
        else:
            return
        self._sync_layer_z()

    # ── group / ungroup ────────────────────────────────────────────────────
    def group_selected(self):
        """Wrap all selected top-level items into a new GroupItem."""
        selected = [i for i in self.selectedItems()
                    if isinstance(i, (IndicatorItem, GroupItem))
                    and i.parentItem() is None]
        if len(selected) < 2:
            return

        # Bounding rect in scene coordinates
        bounding = QRectF()
        for item in selected:
            bounding = bounding.united(item.mapRectToScene(item.boundingRect()))
        origin = bounding.topLeft()

        # Record scene positions before reparenting
        scene_positions = {item: item.scenePos() for item in selected}

        # Create group and add to scene
        group = GroupItem()
        group.setPos(origin)
        self.addItem(group)

        # Reparent each item; set local position relative to group
        for item in selected:
            item.setParentItem(group)
            item.setPos(group.mapFromScene(scene_positions[item]))

        self.clearSelection()
        group.setSelected(True)
        self.item_added.emit()

    def ungroup_selected(self):
        """Release children of the selected GroupItems one nesting level up."""
        groups = [i for i in self.selectedItems() if isinstance(i, GroupItem)]
        if not groups:
            return

        self.clearSelection()
        for group in groups:
            parent = group.parentItem()   # None = scene level; GroupItem = nested
            children = [c for c in group.childItems()
                        if isinstance(c, (IndicatorItem, GroupItem))]
            for child in children:
                scene_pos = child.scenePos()
                child.setParentItem(parent)  # None makes it a scene-level item
                if parent is None:
                    child.setPos(scene_pos)
                else:
                    child.setPos(parent.mapFromScene(scene_pos))
                child.setSelected(True)
            self.removeItem(group)

        self.item_removed.emit()


# ─────────────────────────────────────────────
#  CANVAS VIEW  (QGraphicsView)
# ─────────────────────────────────────────────

class CanvasView(QGraphicsView):
    def __init__(self, scene: CanvasScene, parent=None):
        super().__init__(scene, parent)
        self.setRenderHint(QPainter.Antialiasing)
        self.setDragMode(QGraphicsView.RubberBandDrag)
        self.setViewportUpdateMode(QGraphicsView.FullViewportUpdate)
        self.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOn)
        self.setVerticalScrollBarPolicy(Qt.ScrollBarAlwaysOn)
        self.setTransformationAnchor(QGraphicsView.AnchorUnderMouse)
        self.setFocusPolicy(Qt.StrongFocus)
        self.setAcceptDrops(True)
        self._scale = 1.0
        self._panning      = False
        self._pan_start    = QPoint()

    def wheelEvent(self, event):
        if event.modifiers() & Qt.ControlModifier:
            factor = 1.12 if event.angleDelta().y() > 0 else 1 / 1.12
            self._scale = max(0.1, min(8.0, self._scale * factor))
            self.setTransform(QTransform().scale(self._scale, self._scale))
            event.accept()
        else:
            super().wheelEvent(event)

    # ── middle-mouse panning ───────────────────────────────────────────────
    def mousePressEvent(self, event):
        if event.button() == Qt.MiddleButton:
            self._panning   = True
            self._pan_start = event.position().toPoint()
            self.setCursor(Qt.ClosedHandCursor)
            event.accept()
            return

        if event.button() == Qt.LeftButton:
            sc = self.scene()
            if isinstance(sc, CanvasScene):
                scene_pos = self.mapToScene(event.position().toPoint())
                hit = [i for i in sc.items(scene_pos) if isinstance(i, IndicatorItem)]
                if hit and not hit[0]._handle_rect().contains(hit[0].mapFromScene(scene_pos)):
                    clicked = hit[0]

                    if event.modifiers() & Qt.ControlModifier:
                        # Ctrl+drag: clone all selected items, drag the originals
                        selected = [i for i in sc.selectedItems() if isinstance(i, IndicatorItem)]
                        if clicked not in selected:
                            selected = [clicked]
                        for src in selected:
                            sc.addItem(IndicatorItem._make_clone(src))
                        sc.item_added.emit()
                        sc._drag_origins = {i: i.pos() for i in selected}
                        sc._drag_active  = True
                        sc._copy_mode    = False
                        # Strip Ctrl so Qt starts a normal move drag (no selection toggle)
                        no_ctrl = QMouseEvent(
                            event.type(), event.position(), event.globalPosition(),
                            event.button(), event.buttons(), Qt.NoModifier,
                        )
                        super().mousePressEvent(no_ctrl)
                        # Re-select all drag items (super() may have adjusted selection)
                        sc.clearSelection()
                        for i in selected:
                            i.setSelected(True)
                        return
                    else:
                        # Plain drag: let Qt handle, then record origins
                        super().mousePressEvent(event)
                        # Record origins AFTER Qt settles the selection (positions unchanged)
                        selected = [i for i in sc.selectedItems() if isinstance(i, IndicatorItem)]
                        if selected:
                            sc._drag_origins = {i: i.pos() for i in selected}
                            sc._drag_active  = True
                            sc._copy_mode    = False
                        return

        super().mousePressEvent(event)

    def mouseMoveEvent(self, event):
        if self._panning:
            delta = event.position().toPoint() - self._pan_start
            self._pan_start = event.position().toPoint()
            self.horizontalScrollBar().setValue(
                self.horizontalScrollBar().value() - delta.x())
            self.verticalScrollBar().setValue(
                self.verticalScrollBar().value() - delta.y())
            event.accept()
        else:
            super().mouseMoveEvent(event)

    def mouseReleaseEvent(self, event):
        if event.button() == Qt.MiddleButton:
            self._panning = False
            self.setCursor(Qt.ArrowCursor)
            event.accept()
        else:
            super().mouseReleaseEvent(event)

    def fit_canvas(self) -> None:
        s = self.scene()
        self.fitInView(
            QRectF(s.canvas_x - 20, s.canvas_y - 20,
                   s.canvas_w + 40, s.canvas_h + 40),
            Qt.KeepAspectRatio,
        )
        self._scale = self.transform().m11()

    def keyPressEvent(self, event):
        """Activate ghost-copy mode when Ctrl is pressed while dragging."""
        if event.key() == Qt.Key_Control:
            s = self.scene()
            if isinstance(s, CanvasScene) and s._drag_active and not s._copy_mode:
                s._activate_copy_mode()
        super().keyPressEvent(event)

    def zoom_in(self)  -> None: self._apply_zoom(1.2)
    def zoom_out(self) -> None: self._apply_zoom(1/1.2)

    def _apply_zoom(self, factor: float) -> None:
        self._scale = max(0.1, min(8.0, self._scale * factor))
        self.setTransform(QTransform().scale(self._scale, self._scale))

    def dragEnterEvent(self, event):
        if event.mimeData().hasText():
            event.acceptProposedAction()

    def dragMoveEvent(self, event):
        if event.mimeData().hasText():
            event.acceptProposedAction()

    def dropEvent(self, event):
        if event.mimeData().hasText():
            obj_type = event.mimeData().text()
            scene_pos = self.mapToScene(event.position().toPoint())
            scene = self.scene()
            item = scene.add_indicator(obj_type, scene_pos)
            scene.clearSelection()
            item.setSelected(True)
            event.acceptProposedAction()

    def contextMenuEvent(self, event):
        sc = self.scene()
        if not isinstance(sc, CanvasScene):
            return

        selected = sc.selectedItems()
        top_selected = [i for i in selected
                        if isinstance(i, (IndicatorItem, GroupItem))
                        and i.parentItem() is None]
        can_group   = len(top_selected) >= 2
        can_ungroup = any(isinstance(i, GroupItem) for i in top_selected)

        # Single top-level item → determine if it has layer peers for ordering options
        single = top_selected[0] if len(top_selected) == 1 else None
        can_order = False
        if single is not None:
            lname = getattr(single, 'layer', 'default')
            peers = [i for i in sc.items()
                     if isinstance(i, (IndicatorItem, GroupItem))
                     and i.parentItem() is None
                     and getattr(i, 'layer', 'default') == lname]
            can_order = len(peers) > 1

        if not can_group and not can_ungroup and not can_order:
            return

        menu = QMenu(self)

        if can_order:
            order_menu = menu.addMenu("Layer Order")
            a_up    = order_menu.addAction("Move Up in Layer")
            a_down  = order_menu.addAction("Move Down in Layer")
            order_menu.addSeparator()
            a_front = order_menu.addAction("Bring to Front of Layer")
            a_back  = order_menu.addAction("Send to Back of Layer")
            a_up.triggered.connect(lambda: sc.move_item_in_layer(single, 'up'))
            a_down.triggered.connect(lambda: sc.move_item_in_layer(single, 'down'))
            a_front.triggered.connect(lambda: sc.move_item_in_layer(single, 'front'))
            a_back.triggered.connect(lambda: sc.move_item_in_layer(single, 'back'))

        if (can_group or can_ungroup) and can_order:
            menu.addSeparator()
        if can_group:
            act_group = menu.addAction("Group Selection  \tCtrl+G")
            act_group.triggered.connect(sc.group_selected)
        if can_ungroup:
            act_ungroup = menu.addAction("Ungroup  \tCtrl+Shift+G")
            act_ungroup.triggered.connect(sc.ungroup_selected)

        menu.exec(event.globalPos())


# ─────────────────────────────────────────────
#  PROPERTIES PANEL
# ─────────────────────────────────────────────

class PropertiesPanel(QWidget):
    """Displays and edits properties of the selected IndicatorItem."""

    property_changed = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._item: Optional[IndicatorItem] = None
        self._updating = False
        self._build_ui()

    def _build_ui(self):
        self.setMinimumWidth(220)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(6, 6, 6, 6)

        title = QLabel("Properties")
        title.setStyleSheet("font-weight:bold; font-size:12px; color:#CCCCCC;")
        layout.addWidget(title)

        sep = QFrame(); sep.setFrameShape(QFrame.HLine)
        sep.setStyleSheet("color:#555;")
        layout.addWidget(sep)

        form = QFormLayout()
        form.setLabelAlignment(Qt.AlignRight)
        form.setSpacing(6)

        def mk_label(txt):
            lbl = QLabel(txt)
            lbl.setStyleSheet("color:#AAAAAA; font-size:10px;")
            return lbl

        # Type (read-only)
        self.type_lbl = QLabel("—")
        self.type_lbl.setStyleSheet("color:#00CFFF; font-weight:bold;")
        form.addRow(mk_label("Type:"), self.type_lbl)

        # Label
        self.label_edit = QLineEdit()
        self.label_edit.setPlaceholderText("Label text")
        self.label_edit.textChanged.connect(self._on_label)
        form.addRow(mk_label("Label:"), self.label_edit)

        # Width / Height
        self.width_spin = QSpinBox(); self.width_spin.setRange(20, 4000)
        self.height_spin = QSpinBox(); self.height_spin.setRange(20, 4000)
        self.width_spin.valueChanged.connect(self._on_size)
        self.height_spin.valueChanged.connect(self._on_size)
        form.addRow(mk_label("Width:"), self.width_spin)
        form.addRow(mk_label("Height:"), self.height_spin)

        # X / Y (st_pix)
        self.x_spin = QSpinBox(); self.x_spin.setRange(-9999, 9999)
        self.y_spin = QSpinBox(); self.y_spin.setRange(-9999, 9999)
        self.x_spin.valueChanged.connect(self._on_pos)
        self.y_spin.valueChanged.connect(self._on_pos)
        form.addRow(mk_label("X (px):"), self.x_spin)
        form.addRow(mk_label("Y (px):"), self.y_spin)

        # Min / Max
        self.min_spin = QDoubleSpinBox()
        self.max_spin = QDoubleSpinBox()
        for sp in (self.min_spin, self.max_spin):
            sp.setRange(-1e9, 1e9); sp.setDecimals(2)
        self.min_spin.valueChanged.connect(self._on_minmax)
        self.max_spin.valueChanged.connect(self._on_minmax)
        self.min_lbl = mk_label("Min:")
        self.max_lbl = mk_label("Max:")
        form.addRow(self.min_lbl, self.min_spin)
        form.addRow(self.max_lbl, self.max_spin)

        # Color
        color_row = QHBoxLayout()
        self.color_btn = QPushButton()
        self.color_btn.setFixedSize(48, 24)
        self.color_btn.clicked.connect(self._pick_color)
        self.color_lbl = QLabel("#00CFFF")
        self.color_lbl.setStyleSheet("color:#AAAAAA; font-size:10px;")
        color_row.addWidget(self.color_btn)
        color_row.addWidget(self.color_lbl)
        color_row.addStretch()
        form.addRow(mk_label("Color:"), color_row)

        # Layer
        self.layer_combo = QComboBox()
        self.layer_combo.addItem("default")
        self.layer_combo.currentTextChanged.connect(self._on_layer_changed)
        form.addRow(mk_label("Layer:"), self.layer_combo)

        layout.addLayout(form)

        # ── 7-Segment specific options (shown only for seven_seg) ──────────
        self.seg_group = QWidget()
        seg_layout = QVBoxLayout(self.seg_group)
        seg_layout.setContentsMargins(0, 4, 0, 0)
        seg_layout.setSpacing(4)

        seg_title = QLabel("7-Segment Options")
        seg_title.setStyleSheet("color:#888; font-size:10px; font-style:italic;")
        seg_layout.addWidget(seg_title)

        self.seg_italic_chk = QCheckBox("Italic (slant)")
        self.seg_italic_chk.setStyleSheet("color:#CCCCCC; font-size:10px;")
        self.seg_italic_chk.toggled.connect(self._on_seg_italic)
        seg_layout.addWidget(self.seg_italic_chk)

        self.seg_hex_chk = QCheckBox("Hex Mode (0–F)")
        self.seg_hex_chk.setStyleSheet("color:#CCCCCC; font-size:10px;")
        self.seg_hex_chk.toggled.connect(self._on_seg_hex)
        seg_layout.addWidget(self.seg_hex_chk)

        self.seg_group.hide()
        layout.addWidget(self.seg_group)

        # ── Numeric Readout specific ────────────────────────────────────────
        self.num_group = QWidget()
        num_layout = QVBoxLayout(self.num_group)
        num_layout.setContentsMargins(0, 4, 0, 0)
        num_layout.setSpacing(4)

        num_title = QLabel("Numeric Readout Options")
        num_title.setStyleSheet("color:#888; font-size:10px; font-style:italic;")
        num_layout.addWidget(num_title)

        num_form = QFormLayout()
        num_form.setLabelAlignment(Qt.AlignRight)
        num_form.setSpacing(4)

        self.unit_edit = QLineEdit()
        self.unit_edit.setPlaceholderText("e.g. km/h, °C, %")
        self.unit_edit.textChanged.connect(self._on_unit)
        num_form.addRow(mk_label("Unit:"), self.unit_edit)

        self.dec_spin = QSpinBox()
        self.dec_spin.setRange(0, 6)
        self.dec_spin.setValue(1)
        self.dec_spin.valueChanged.connect(self._on_dec)
        num_form.addRow(mk_label("Decimals:"), self.dec_spin)

        num_layout.addLayout(num_form)
        self.num_group.hide()
        layout.addWidget(self.num_group)

        # ── Text / Container specific ───────────────────────────────────────
        self.txt_group = QWidget()
        txt_layout = QVBoxLayout(self.txt_group)
        txt_layout.setContentsMargins(0, 4, 0, 0)
        txt_layout.setSpacing(4)

        txt_title = QLabel("Text Data")
        txt_title.setStyleSheet("color:#888; font-size:10px; font-style:italic;")
        txt_layout.addWidget(txt_title)

        self.static_edit = QLineEdit()
        self.static_edit.setPlaceholderText("Display text")
        self.static_edit.textChanged.connect(self._on_static_text)
        self.font_combo = QFontComboBox()
        self.font_combo.setCurrentFont(QFont("Segoe UI"))
        self.font_combo.currentFontChanged.connect(self._on_font_family)
        txt_form = QFormLayout()
        txt_form.setLabelAlignment(Qt.AlignRight)
        txt_form.setSpacing(4)
        txt_form.addRow(mk_label("Text Data:"), self.static_edit)
        txt_form.addRow(mk_label("Font:"), self.font_combo)
        txt_layout.addLayout(txt_form)
        self.txt_group.hide()
        layout.addWidget(self.txt_group)

        # ── Shape properties (shown for shape_* types) ──────────────────────
        self.shape_group = QWidget()
        shape_layout = QVBoxLayout(self.shape_group)
        shape_layout.setContentsMargins(0, 4, 0, 0)
        shape_layout.setSpacing(4)

        shape_title = QLabel("Shape Options")
        shape_title.setStyleSheet("color:#888; font-size:10px; font-style:italic;")
        shape_layout.addWidget(shape_title)

        self.fill_chk = QCheckBox("Fill enabled")
        self.fill_chk.setStyleSheet("color:#CCCCCC; font-size:10px;")
        self.fill_chk.setChecked(True)
        self.fill_chk.toggled.connect(self._on_fill_enabled)
        shape_layout.addWidget(self.fill_chk)

        shape_form = QFormLayout()
        shape_form.setLabelAlignment(Qt.AlignRight)
        shape_form.setSpacing(4)

        stroke_row = QHBoxLayout()
        self.stroke_btn = QPushButton()
        self.stroke_btn.setFixedSize(48, 24)
        self.stroke_btn.clicked.connect(self._pick_stroke_color)
        self.stroke_lbl = QLabel("#FFFFFF")
        self.stroke_lbl.setStyleSheet("color:#AAAAAA; font-size:10px;")
        stroke_row.addWidget(self.stroke_btn)
        stroke_row.addWidget(self.stroke_lbl)
        stroke_row.addStretch()
        shape_form.addRow(mk_label("Border:"), stroke_row)

        self.stroke_spin = QDoubleSpinBox()
        self.stroke_spin.setRange(0.5, 30.0)
        self.stroke_spin.setSingleStep(0.5)
        self.stroke_spin.setValue(2.0)
        self.stroke_spin.valueChanged.connect(self._on_stroke_width)
        shape_form.addRow(mk_label("Thickness:"), self.stroke_spin)

        shape_layout.addLayout(shape_form)

        # Bezier control points (only shown for shape_bezier)
        self.bz_group = QWidget()
        bz_layout = QVBoxLayout(self.bz_group)
        bz_layout.setContentsMargins(0, 2, 0, 0)
        bz_layout.setSpacing(2)
        bz_title = QLabel("Bezier Control Points (0–100%)")
        bz_title.setStyleSheet("color:#777; font-size:9px;")
        bz_layout.addWidget(bz_title)
        bz_form = QFormLayout()
        bz_form.setLabelAlignment(Qt.AlignRight)
        bz_form.setSpacing(3)
        self.bcp1x = QSpinBox(); self.bcp1x.setRange(0, 100); self.bcp1x.setValue(25)
        self.bcp1y = QSpinBox(); self.bcp1y.setRange(0, 100); self.bcp1y.setValue(0)
        self.bcp2x = QSpinBox(); self.bcp2x.setRange(0, 100); self.bcp2x.setValue(75)
        self.bcp2y = QSpinBox(); self.bcp2y.setRange(0, 100); self.bcp2y.setValue(0)
        for sp in (self.bcp1x, self.bcp1y, self.bcp2x, self.bcp2y):
            sp.valueChanged.connect(self._on_bezier_cp)
        bz_form.addRow(mk_label("CP1 X:"), self.bcp1x)
        bz_form.addRow(mk_label("CP1 Y:"), self.bcp1y)
        bz_form.addRow(mk_label("CP2 X:"), self.bcp2x)
        bz_form.addRow(mk_label("CP2 Y:"), self.bcp2y)
        bz_layout.addLayout(bz_form)
        self.bz_group.hide()
        shape_layout.addWidget(self.bz_group)

        self.shape_group.hide()
        layout.addWidget(self.shape_group)

        layout.addStretch()

        self._set_enabled(False)

    def _set_enabled(self, en: bool):
        for w in (self.label_edit, self.width_spin, self.height_spin,
                  self.x_spin, self.y_spin, self.min_spin, self.max_spin,
                  self.color_btn, self.unit_edit, self.dec_spin,
                  self.static_edit, self.font_combo,
                  self.layer_combo, self.fill_chk, self.stroke_btn, self.stroke_spin,
                  self.bcp1x, self.bcp1y, self.bcp2x, self.bcp2y):
            w.setEnabled(en)

    def _update_color_btn(self, color: QColor):
        self.color_btn.setStyleSheet(
            f"background-color:{color.name()}; border:1px solid #555; border-radius:3px;")
        self.color_lbl.setText(color.name())

    def _update_stroke_btn(self, color: QColor):
        self.stroke_btn.setStyleSheet(
            f"background-color:{color.name()}; border:1px solid #555; border-radius:3px;")
        self.stroke_lbl.setText(color.name())

    def refresh_layer_combo(self, scene=None):
        """Repopulate layer combo from scene.layers. Call after layers change."""
        sc = scene or (self._item.scene() if self._item else None)
        if not sc:
            return
        self.layer_combo.blockSignals(True)
        current = self.layer_combo.currentText()
        self.layer_combo.clear()
        for lyr in sc.layers:
            self.layer_combo.addItem(lyr.name)
        idx = self.layer_combo.findText(current)
        self.layer_combo.setCurrentIndex(max(0, idx))
        self.layer_combo.blockSignals(False)

    def load_item(self, item):
        self._item = item
        if item is None:
            self.type_lbl.setText("—")
            self._set_enabled(False)
            self.seg_group.hide()
            self.num_group.hide()
            self.txt_group.hide()
            self.shape_group.hide()
            return
        self._updating = True
        self.type_lbl.setText(INDICATOR_LABELS.get(item.obj_type, item.obj_type))
        self.label_edit.setText(item.label)
        self.width_spin.setValue(int(item.obj_w))
        self.height_spin.setValue(int(item.obj_h))
        px, py = item.st_pix()
        self.x_spin.setValue(px)
        self.y_spin.setValue(py)
        self.min_spin.setValue(item.min_val)
        self.max_spin.setValue(item.max_val)
        self._update_color_btn(item.color)
        # Layer combo
        if item.scene():
            self.refresh_layer_combo(item.scene())
        self.layer_combo.blockSignals(True)
        idx = self.layer_combo.findText(item.layer)
        self.layer_combo.setCurrentIndex(max(0, idx))
        self.layer_combo.blockSignals(False)
        # Show 7-seg options
        is_seg = (item.obj_type == "seven_seg")
        self.seg_group.setVisible(is_seg)
        if is_seg:
            self.seg_italic_chk.setChecked(item.seg_italic)
            self.seg_hex_chk.setChecked(item.seg_hex_mode)
        # Show numeric-readout options
        is_num = (item.obj_type == "numeric_readout")
        self.num_group.setVisible(is_num)
        if is_num:
            self.unit_edit.setText(item.unit_label)
            self.dec_spin.setValue(item.decimal_places)
        # Show text/container options
        is_txt = (item.obj_type == "text_label")
        self.txt_group.setVisible(is_txt)
        if is_txt:
            self.static_edit.setText(item.static_text)
            self.font_combo.blockSignals(True)
            self.font_combo.setCurrentFont(QFont(item.font_family or "Segoe UI"))
            self.font_combo.blockSignals(False)
        # Show shape options
        is_shape = item.obj_type.startswith("shape_")
        self.min_lbl.setVisible(not is_shape)
        self.min_spin.setVisible(not is_shape)
        self.max_lbl.setVisible(not is_shape)
        self.max_spin.setVisible(not is_shape)
        self.shape_group.setVisible(is_shape)
        if is_shape:
            self.fill_chk.setChecked(item.fill_enabled)
            self._update_stroke_btn(item.stroke_color)
            self.stroke_spin.setValue(item.stroke_width)
            is_bezier = (item.obj_type == "shape_bezier")
            self.bz_group.setVisible(is_bezier)
            if is_bezier:
                for sp, v in zip((self.bcp1x, self.bcp1y, self.bcp2x, self.bcp2y),
                                  item.bezier_cp1 + item.bezier_cp2):
                    sp.blockSignals(True)
                    sp.setValue(int(v * 100))
                    sp.blockSignals(False)
        self._set_enabled(True)
        self._updating = False

    def refresh_pos(self, item):
        if item is self._item and not self._updating:
            self._updating = True
            px, py = item.st_pix()
            self.x_spin.setValue(px)
            self.y_spin.setValue(py)
            self.width_spin.setValue(int(item.obj_w))
            self.height_spin.setValue(int(item.obj_h))
            self._updating = False

    # ── slots ──────────────────────────────────────────────────────────────
    def _on_label(self, text):
        if self._item and not self._updating:
            # Check against duplicates of the same type
            if self._item.scene():
                for other in self._item.scene().items_only():
                    if other is not self._item and other.obj_type == self._item.obj_type and other.label == text:
                        QMessageBox.warning(self, "Duplicate Label",
                                            f"The label '{text}' is already in use by another {self._item.obj_type} indicator.\n"
                                            "Please choose a unique name.")
                        self._updating = True
                        self.label_edit.setText(self._item.label)
                        self._updating = False
                        return
            
            self._item.label = text
            self._item.update()

    def _on_size(self):
        if self._item and not self._updating:
            self._item.prepareGeometryChange()
            self._item.obj_w = self.width_spin.value()
            self._item.obj_h = self.height_spin.value()
            self._item.update()
            self.property_changed.emit()

    def _on_pos(self):
        if self._item and not self._updating:
            scene = self._item.scene()
            if scene:
                nx = scene.canvas_x + self.x_spin.value()
                ny = scene.canvas_y + self.y_spin.value()
                self._item.setPos(nx, ny)

    def _on_minmax(self):
        if self._item and not self._updating:
            self._item.min_val = self.min_spin.value()
            self._item.max_val = self.max_spin.value()
            self.property_changed.emit()

    def _pick_color(self):
        if not self._item:
            return
        c = QColorDialog.getColor(self._item.color, self, "Pick Color")
        if c.isValid():
            self._item.color = c
            self._item.update()
            self._update_color_btn(c)
            self.property_changed.emit()

    def _on_seg_italic(self, checked: bool):
        if self._item and not self._updating:
            self._item.seg_italic = checked
            self._item.update()
            self.property_changed.emit()

    def _on_seg_hex(self, checked: bool):
        if self._item and not self._updating:
            self._item.seg_hex_mode = checked
            self._item.update()
            self.property_changed.emit()

    def _on_unit(self, text: str):
        if self._item and not self._updating:
            self._item.unit_label = text
            self._item.update()
            self.property_changed.emit()

    def _on_dec(self, val: int):
        if self._item and not self._updating:
            self._item.decimal_places = val
            self._item.update()
            self.property_changed.emit()

    def _on_static_text(self, text: str):
        if self._item and not self._updating:
            self._item.static_text = text
            self._item.update()
            self.property_changed.emit()

    def _on_font_family(self, font: QFont):
        if self._item and not self._updating:
            self._item.font_family = font.family()
            self._item.update()
            self.property_changed.emit()

    def _on_fill_enabled(self, checked: bool):
        if self._item and not self._updating:
            self._item.fill_enabled = checked
            self._item.update()
            self.property_changed.emit()

    def _pick_stroke_color(self):
        if not self._item:
            return
        c = QColorDialog.getColor(self._item.stroke_color, self, "Pick Border Color")
        if c.isValid():
            self._item.stroke_color = c
            self._item.update()
            self._update_stroke_btn(c)
            self.property_changed.emit()

    def _on_stroke_width(self, val: float):
        if self._item and not self._updating:
            self._item.stroke_width = val
            self._item.update()
            self.property_changed.emit()

    def _on_bezier_cp(self):
        if self._item and not self._updating:
            self._item.bezier_cp1 = [self.bcp1x.value() / 100.0, self.bcp1y.value() / 100.0]
            self._item.bezier_cp2 = [self.bcp2x.value() / 100.0, self.bcp2y.value() / 100.0]
            self._item.update()
            self.property_changed.emit()

    def _on_layer_changed(self, name: str):
        if self._item and not self._updating:
            sc = self._item.scene()
            if sc:
                sc.set_item_layer(self._item, name)


# ─────────────────────────────────────────────
#  VALUE PREVIEW PANEL
# ─────────────────────────────────────────────

class PreviewPanel(QWidget):
    """Live value preview – renders indicator at a test value."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self._item: Optional[IndicatorItem] = None
        self._build_ui()

    def _build_ui(self):
        self.setMinimumWidth(220)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(6, 6, 6, 6)

        title = QLabel("Value Preview")
        title.setStyleSheet("font-weight:bold; font-size:12px; color:#CCCCCC;")
        layout.addWidget(title)

        sep = QFrame(); sep.setFrameShape(QFrame.HLine)
        sep.setStyleSheet("color:#555;")
        layout.addWidget(sep)

        # Preview image
        self.preview_lbl = QLabel()
        self.preview_lbl.setAlignment(Qt.AlignCenter)
        self.preview_lbl.setMinimumHeight(130)
        self.preview_lbl.setStyleSheet(
            "background:#1A1A2E; border:1px solid #444; border-radius:6px;")
        layout.addWidget(self.preview_lbl)

        # Fraction label
        self.frac_lbl = QLabel("0%")
        self.frac_lbl.setAlignment(Qt.AlignCenter)
        self.frac_lbl.setStyleSheet("color:#888; font-size:10px;")
        layout.addWidget(self.frac_lbl)

        # Slider
        self.slider = QSlider(Qt.Horizontal)
        self.slider.setRange(0, 1000)
        self.slider.setValue(0)
        self.slider.valueChanged.connect(self._on_slider)
        layout.addWidget(self.slider)

        # Value spinbox
        val_row = QHBoxLayout()
        val_lbl = QLabel("Value:")
        val_lbl.setStyleSheet("color:#AAAAAA; font-size:10px;")
        self.val_spin = QDoubleSpinBox()
        self.val_spin.setRange(-1e9, 1e9)
        self.val_spin.setDecimals(2)
        self.val_spin.valueChanged.connect(self._on_val_spin)
        
        self.val_seg_combo = QComboBox()
        self.val_seg_combo.currentIndexChanged.connect(self._on_seg_combo)
        
        val_row.addWidget(val_lbl)
        val_row.addWidget(self.val_spin)
        val_row.addWidget(self.val_seg_combo)
        layout.addLayout(val_row)

        layout.addStretch()

    def load_item(self, item):
        # Do not clear preview state from old item, so it's persistent!
        # if self._item is not None and self._item is not item:
        #     self._item._preview_fraction = None
        #     self._item.update()
        self._item = item
        if item is None:
            self.preview_lbl.clear()
            self.preview_lbl.setText("No selection")
            self.slider.setValue(0)
            return

        is_seg = (item.obj_type == "seven_seg")
        self.slider.setVisible(not is_seg)
        self.val_spin.setVisible(not is_seg)
        self.val_seg_combo.setVisible(is_seg)

        if is_seg:
            self.val_seg_combo.blockSignals(True)
            self.val_seg_combo.clear()
            items = ["Empty", "-"] + [str(i) for i in range(10)]
            if item.seg_hex_mode:
                items += ["A", "B", "C", "D", "E", "F"]
            self.val_seg_combo.addItems(items)
            
            if item._preview_fraction is not None:
                if item._preview_fraction <= -0.5:
                    idx = 0
                elif item._preview_fraction < 0.0:
                    idx = 1
                else:
                    max_val = 15 if item.seg_hex_mode else 9
                    val = int(round(item._preview_fraction * max_val))
                    idx = val + 2
                self.val_seg_combo.setCurrentIndex(idx)
                self.val_seg_combo.blockSignals(False)
                self._refresh_preview(item._preview_fraction)
            else:
                self.val_seg_combo.setCurrentIndex(0)
                self.val_seg_combo.blockSignals(False)
                self._refresh_preview(-1.0) # Start on empty
        else:
            self.val_spin.setRange(item.min_val, item.max_val)
            if item._preview_fraction is not None:
                v = item.min_val + item._preview_fraction * (item.max_val - item.min_val)
                self.val_spin.setValue(v)
                self._refresh_preview(item._preview_fraction)
            else:
                self.val_spin.setValue(item.min_val)
                self._refresh_preview(0.0)

    def refresh(self):
        """Called when item properties change."""
        if self._item:
            self.load_item(self._item)

    def _fraction(self) -> float:
        if not self._item:
            return 0.0
        span = self._item.max_val - self._item.min_val
        if span == 0:
            return 0.0
        return (self.val_spin.value() - self._item.min_val) / span

    def _on_slider(self, val: int):
        if not self._item:
            return
        frac = val / 1000.0
        v = self._item.min_val + frac * (self._item.max_val - self._item.min_val)
        # Block spinbox signal to avoid loop
        self.val_spin.blockSignals(True)
        self.val_spin.setValue(v)
        self.val_spin.blockSignals(False)
        self._refresh_preview(frac)

    def _on_val_spin(self, v: float):
        if not self._item:
            return
            
        span = self._item.max_val - self._item.min_val
        if span == 0:
            frac = 0.0
        else:
            frac = (v - self._item.min_val) / span

        if self._item.obj_type == "seven_seg":
            # Round frac to discrete steps for 7-seg
            steps = 15 if self._item.seg_hex_mode else 9
            frac = round(frac * steps) / float(steps)

        self.slider.blockSignals(True)
        self.slider.setValue(int(frac * 1000))
        self.slider.blockSignals(False)
        self._refresh_preview(frac)

    def _on_seg_combo(self, idx: int):
        if not self._item:
            return
        if idx == 0:
            frac = -1.0 # Empty
        elif idx == 1:
            frac = -0.01 # '-'
        else:
            val = idx - 2
            max_val = 15 if self._item.seg_hex_mode else 9
            frac = val / float(max_val)
        self._refresh_preview(frac)

    def _refresh_preview(self, frac: float):
        if not self._item:
            return
        self.frac_lbl.setText(f"{frac*100:.1f}%")
        # --- Update canvas item so it shows the preview state live ---
        self._item._preview_fraction = frac
        self._item.update()
        # --- Side-panel pixmap preview ---
        lw = max(self.preview_lbl.width() - 10, 80)
        lh = max(self.preview_lbl.height() - 10, 60)
        iw, ih = int(self._item.obj_w), int(self._item.obj_h)
        scale = min(lw / max(iw, 1), lh / max(ih, 1), 1.5)
        pw, ph = max(20, int(iw * scale)), max(20, int(ih * scale))
        if self._item.obj_type == "seven_seg":
            pm = QPixmap(pw, ph)
            pm.fill(Qt.transparent)
            p = QPainter(pm)
            p.setRenderHint(QPainter.Antialiasing)
            _draw_seven_seg(p, QRectF(0, 0, pw, ph), frac, self._item.color,
                            empty=False,
                            italic=self._item.seg_italic,
                            hex_mode=self._item.seg_hex_mode)
            p.end()
        else:
            pm = render_to_pixmap(self._item.obj_type, pw, ph,
                                  self._item.color, frac,
                                  transparent_bg=False,
                                  static_text=self._item.static_text,
                                  unit=self._item.unit_label,
                                  decimal_places=self._item.decimal_places,
                                  font_family=self._item.font_family,
                                  stroke_color=self._item.stroke_color,
                                  stroke_width=self._item.stroke_width,
                                  fill_enabled=self._item.fill_enabled,
                                  bezier_cp1=self._item.bezier_cp1,
                                  bezier_cp2=self._item.bezier_cp2)
        self.preview_lbl.setPixmap(pm)


# ─────────────────────────────────────────────
#  LAYER PANEL
# ─────────────────────────────────────────────

class LayerPanel(QWidget):
    """Paint-software-style layer stack: create/delete/reorder/toggle visibility."""

    def __init__(self, scene=None, parent=None):
        super().__init__(parent)
        self._scene = scene
        self._updating = False
        self._pending_select: str | None = None
        self._build_ui()
        if scene:
            self.refresh()

    def set_scene(self, scene):
        self._scene = scene
        self.refresh()

    def _build_ui(self):
        self.setMinimumWidth(220)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(6, 6, 6, 6)
        layout.setSpacing(4)

        hint = QLabel("Top = front  \u00b7  \u2611 = visible  \u00b7  Dbl-click = set active")
        hint.setStyleSheet("color:#666; font-size:9px;")
        hint.setWordWrap(True)
        layout.addWidget(hint)

        self.list_widget = QListWidget()
        self.list_widget.setDragDropMode(QListWidget.NoDragDrop)
        self.list_widget.setStyleSheet("""
            QListWidget {
                background: #252535; border: 1px solid #444;
                border-radius: 4px; color: #CCCCCC; font-size: 11px;
            }
            QListWidget::item { padding: 4px 6px; }
            QListWidget::item:selected { background: #333355; }
            QListWidget::item:hover { background: #2d2d4d; }
        """)
        self.list_widget.itemChanged.connect(self._on_item_changed)
        self.list_widget.itemDoubleClicked.connect(self._set_active_layer)
        layout.addWidget(self.list_widget)

        btn_row = QHBoxLayout()
        btn_row.setSpacing(3)

        def _mk_btn(label, tip, slot):
            b = QPushButton(label)
            b.setFixedWidth(32)
            b.setFixedHeight(26)
            b.setToolTip(tip)
            b.clicked.connect(slot)
            return b

        btn_row.addWidget(_mk_btn("+",  "New layer",        self._add_layer))
        btn_row.addWidget(_mk_btn("\U0001f5d1", "Delete layer",     self._del_layer))
        btn_row.addWidget(_mk_btn("\u25b2",  "Move layer up",    self._move_up))
        btn_row.addWidget(_mk_btn("\u25bc",  "Move layer down",  self._move_down))
        btn_row.addStretch()
        layout.addLayout(btn_row)

    def refresh(self):
        if not self._scene:
            return
        self._updating = True
        self.list_widget.blockSignals(True)
        self.list_widget.clear()
        active = getattr(self._scene, 'active_layer', 'default')
        # Display top layer first (reversed: last in list = front)
        for lyr in reversed(self._scene.layers):
            count = sum(1 for item in self._scene.items()
                        if isinstance(item, (IndicatorItem, GroupItem))
                        and getattr(item, 'layer', 'default') == lyr.name
                        and item.parentItem() is None)
            is_active = (lyr.name == active)
            label = f"{lyr.name}  ({count})  \u25cf" if is_active else f"{lyr.name}  ({count})"
            lw = QListWidgetItem(label)
            lw.setData(Qt.UserRole, lyr.name)
            lw.setFlags(Qt.ItemIsEnabled | Qt.ItemIsSelectable | Qt.ItemIsUserCheckable)
            lw.setCheckState(Qt.Checked if lyr.visible else Qt.Unchecked)
            if lyr.name == "default":
                lw.setForeground(QColor("#00CFFF"))
            if is_active:
                lw.setForeground(QColor("#FFD600"))
            self.list_widget.addItem(lw)
        # Restore pending selection (e.g. after reorder buttons)
        if self._pending_select is not None:
            for i in range(self.list_widget.count()):
                if self.list_widget.item(i).data(Qt.UserRole) == self._pending_select:
                    self.list_widget.setCurrentRow(i)
                    break
            self._pending_select = None
        self.list_widget.blockSignals(False)
        self._updating = False

    def _on_item_changed(self, lw: QListWidgetItem):
        if self._updating or not self._scene:
            return
        name = lw.data(Qt.UserRole)
        visible = (lw.checkState() == Qt.Checked)
        self._scene.set_layer_visible(name, visible)

    def _set_active_layer(self, lw: QListWidgetItem):
        if not self._scene:
            return
        name = lw.data(Qt.UserRole)
        self._scene.active_layer = name
        self.refresh()

    def _rename_layer(self, lw: QListWidgetItem):
        if not self._scene:
            return
        old_name = lw.data(Qt.UserRole)
        if old_name == "default":
            QMessageBox.warning(self, "Rename Layer",
                                "The 'default' layer cannot be renamed.")
            return
        new_name, ok = QInputDialog.getText(self, "Rename Layer",
                                             "New name:", text=old_name)
        if ok and new_name.strip():
            if not self._scene.rename_layer(old_name, new_name.strip()):
                QMessageBox.warning(self, "Rename Layer",
                                    f"Layer '{new_name}' already exists.")

    def _add_layer(self):
        if not self._scene:
            return
        name, ok = QInputDialog.getText(self, "New Layer", "Layer name:")
        if ok and name.strip():
            if not self._scene.add_layer(name.strip()):
                QMessageBox.warning(self, "New Layer",
                                    f"Layer '{name}' already exists.")

    def _del_layer(self):
        row = self.list_widget.currentRow()
        if row < 0 or not self._scene:
            return
        name = self.list_widget.item(row).data(Qt.UserRole)
        if name == "default":
            QMessageBox.warning(self, "Delete Layer",
                                "Cannot delete the 'default' layer.")
            return
        ret = QMessageBox.question(
            self, "Delete Layer",
            f"Delete layer '{name}'?\nAll items in it will move to 'default'.",
            QMessageBox.Yes | QMessageBox.No,
        )
        if ret == QMessageBox.Yes:
            self._scene.remove_layer(name)

    def _move_up(self):
        row = self.list_widget.currentRow()
        if row < 0 or not self._scene:
            return
        name = self.list_widget.item(row).data(Qt.UserRole)
        self._pending_select = name
        # List is reversed: row 0 = top layer = last in self._scene.layers
        # Moving "up" in the UI means higher Z → move toward the end of the list
        self._scene.move_layer(name, +1)

    def _move_down(self):
        row = self.list_widget.currentRow()
        if row < 0 or not self._scene:
            return
        name = self.list_widget.item(row).data(Qt.UserRole)
        self._pending_select = name
        self._scene.move_layer(name, -1)


# ─────────────────────────────────────────────
#  INDICATOR PALETTE  (left panel)
# ─────────────────────────────────────────────

class PalettePanel(QWidget):
    """Drag source for indicator types, grouped by category."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setMinimumWidth(160)
        layout = QVBoxLayout(self)
        layout.setContentsMargins(4, 4, 4, 4)

        title = QLabel("Indicators")
        title.setStyleSheet("font-weight:bold; font-size:12px; color:#CCCCCC;")
        layout.addWidget(title)

        self.tree = IndicatorTreeWidget()
        layout.addWidget(self.tree)

        for cat_name, types in INDICATOR_CATEGORIES:
            cat_item = QTreeWidgetItem(self.tree, [cat_name])
            cat_item.setFlags(Qt.ItemIsEnabled)
            cat_item.setForeground(0, QColor("#00CFFF"))
            font = cat_item.font(0)
            font.setBold(True)
            font.setPointSize(9)
            cat_item.setFont(0, font)
            for itype in types:
                child = QTreeWidgetItem(cat_item, [INDICATOR_LABELS[itype]])
                child.setData(0, Qt.UserRole, itype)
                child.setToolTip(0, f"Drag to place a {INDICATOR_LABELS[itype]}")
                child.setFlags(Qt.ItemIsEnabled | Qt.ItemIsSelectable | Qt.ItemIsDragEnabled)

        self.tree.expandAll()
        self.tree.itemDoubleClicked.connect(self._on_double_click)

    def _on_double_click(self, item: QTreeWidgetItem, _col: int):
        obj_type = item.data(0, Qt.UserRole)
        if not obj_type:
            return
        mw = self.window()
        if hasattr(mw, 'scene') and mw.scene:
            mw.scene.add_indicator(obj_type)


from PySide6.QtCore import QMimeData
from PySide6.QtGui import QDrag


class IndicatorTreeWidget(QTreeWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setDragEnabled(True)
        self.setColumnCount(1)
        self.setHeaderHidden(True)
        self.setIndentation(14)
        self.setStyleSheet("""
            QTreeWidget {
                background: #252535;
                border: 1px solid #444;
                border-radius: 4px;
                color: #CCCCCC;
                font-size: 11px;
            }
            QTreeWidget::item { padding: 4px 6px; }
            QTreeWidget::item:selected { background: #00CFFF; color: #000; }
            QTreeWidget::item:hover { background: #333355; }
            QTreeWidget::branch { background: #252535; }
        """)

    def startDrag(self, actions):
        item = self.currentItem()
        if not item:
            return
        obj_type = item.data(0, Qt.UserRole)
        if not obj_type:
            return
        mime = QMimeData()
        mime.setText(obj_type)
        drag = QDrag(self)
        drag.setMimeData(mime)
        drag.exec(Qt.CopyAction)


# ─────────────────────────────────────────────
#  CANVAS SIZE DIALOG
# ─────────────────────────────────────────────

class CanvasSizeDialog(QDialog):
    def __init__(self, w: int, h: int, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Canvas Size")
        self.setFixedSize(280, 140)
        layout = QFormLayout(self)
        self.w_spin = QSpinBox(); self.w_spin.setRange(100, 8000); self.w_spin.setValue(w)
        self.h_spin = QSpinBox(); self.h_spin.setRange(100, 8000); self.h_spin.setValue(h)
        layout.addRow("Width (px):", self.w_spin)
        layout.addRow("Height (px):", self.h_spin)
        btns = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        btns.accepted.connect(self.accept)
        btns.rejected.connect(self.reject)
        layout.addRow(btns)

    def values(self):
        return self.w_spin.value(), self.h_spin.value()


# ─────────────────────────────────────────────
#  EXPORT DIALOG
# ─────────────────────────────────────────────

class ExportDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Export Layout")
        self.setMinimumWidth(360)
        layout = QFormLayout(self)

        # Output directory
        dir_row = QHBoxLayout()
        self.dir_edit = QLineEdit()
        self.dir_edit.setPlaceholderText("Select output directory…")
        browse_btn = QPushButton("Browse…")
        browse_btn.clicked.connect(self._browse)
        dir_row.addWidget(self.dir_edit)
        dir_row.addWidget(browse_btn)
        layout.addRow("Output dir:", dir_row)

        # Format
        self.fmt_combo = QComboBox()
        self.fmt_combo.addItems(["32-bit RGBA", "16-bit RGB565", "Black & White"])
        layout.addRow("Image format:", self.fmt_combo)

        # Embed images in JSON
        self.embed_chk = QCheckBox("Embed images as base64 in JSON")
        self.embed_chk.setChecked(False)
        layout.addRow("", self.embed_chk)

        btns = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        btns.accepted.connect(self.accept)
        btns.rejected.connect(self.reject)
        layout.addRow(btns)

    def _browse(self):
        d = QFileDialog.getExistingDirectory(self, "Select Output Directory")
        if d:
            self.dir_edit.setText(d)

    def values(self):
        fmt_map = {0: "32bit", 1: "16bit", 2: "bw"}
        return (
            self.dir_edit.text().strip(),
            fmt_map[self.fmt_combo.currentIndex()],
            self.embed_chk.isChecked(),
        )


# ─────────────────────────────────────────────
#  MAIN WINDOW
# ─────────────────────────────────────────────

APP_STYLE = """
QMainWindow, QWidget {
    background-color: #1E1E2E;
    color: #CCCCCC;
    font-family: "Segoe UI";
    font-size: 11px;
}
QToolBar {
    background: #252535;
    border-bottom: 1px solid #444;
    spacing: 4px;
    padding: 2px 6px;
}
QToolButton {
    color: #CCCCCC;
    border: none;
    padding: 4px 8px;
    border-radius: 4px;
    font-size: 11px;
}
QToolButton:hover { background: #333355; font-size: 11px; }
QToolButton:pressed { background: #00CFFF; color: #000; font-size: 11px; }
QToolButton:disabled { color: #555566; }
QComboBox:disabled { color: #555566; border-color: #444; }
QSpinBox:disabled { color: #555566; border-color: #444; }
QSplitter::handle { background: #333; }
QSpinBox, QDoubleSpinBox, QLineEdit, QComboBox {
    background: #252535;
    border: 1px solid #555;
    border-radius: 3px;
    padding: 2px 4px;
    color: #CCCCCC;
}
QSpinBox:focus, QDoubleSpinBox:focus, QLineEdit:focus {
    border-color: #00CFFF;
}
QSlider::groove:horizontal {
    background: #333;
    height: 6px;
    border-radius: 3px;
}
QSlider::handle:horizontal {
    background: #00CFFF;
    width: 14px;
    height: 14px;
    margin: -4px 0;
    border-radius: 7px;
}
QPushButton {
    background: #333355;
    border: 1px solid #555;
    border-radius: 4px;
    padding: 4px 10px;
    color: #CCCCCC;
}
QPushButton:hover { background: #444477; border-color: #00CFFF; }
QPushButton:pressed { background: #00CFFF; color: #000; }
QGroupBox {
    border: 1px solid #444;
    border-radius: 5px;
    margin-top: 8px;
    padding: 4px;
}
QGroupBox::title {
    subcontrol-origin: margin;
    left: 8px;
    color: #00CFFF;
}
QScrollBar:vertical { background: #252535; width: 10px; }
QScrollBar::handle:vertical { background: #555; border-radius: 5px; min-height: 20px; }
QCheckBox { color: #CCCCCC; }
QCheckBox::indicator { width: 14px; height: 14px; }
QSpinBox, QDoubleSpinBox {
    min-height: 24px;
    padding-right: 24px;
}
QSpinBox::up-button, QDoubleSpinBox::up-button {
    width: 24px;
}
QSpinBox::down-button, QDoubleSpinBox::down-button {
    width: 24px;
}
"""


# ─────────────────────────────────────────────
#  WELCOME SCREEN
# ─────────────────────────────────────────────

class WelcomeWidget(QWidget):
    new_canvas  = Signal()
    load_canvas = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        layout = QVBoxLayout(self)
        layout.setAlignment(Qt.AlignCenter)
        layout.setSpacing(20)

        title = QLabel("Lacerta-HMI Designer")
        title.setAlignment(Qt.AlignCenter)
        title.setStyleSheet("font-size: 28px; font-weight: bold; color: #00CFFF;")
        layout.addWidget(title)

        sub = QLabel("Create a new canvas or load an existing scene to get started.")
        sub.setAlignment(Qt.AlignCenter)
        sub.setStyleSheet("font-size: 13px; color: #888888;")
        layout.addWidget(sub)

        btn_row = QHBoxLayout()
        btn_row.setAlignment(Qt.AlignCenter)
        btn_row.setSpacing(16)

        btn_new = QPushButton("＋  New Canvas")
        btn_new.setFixedSize(180, 50)
        btn_new.setStyleSheet("font-size: 14px;")
        btn_new.clicked.connect(self.new_canvas)
        btn_row.addWidget(btn_new)

        btn_load = QPushButton("📁  Load Scene")
        btn_load.setFixedSize(180, 50)
        btn_load.setStyleSheet("font-size: 14px;")
        btn_load.clicked.connect(self.load_canvas)
        btn_row.addWidget(btn_load)

        layout.addLayout(btn_row)


# ─────────────────────────────────────────────
#  CANVAS TAB  (one per open canvas)
# ─────────────────────────────────────────────

class CanvasTab(QWidget):
    """Self-contained canvas workspace (palette + canvas + properties + preview)."""

    def __init__(self, name: str,
                 canvas_w: int = DEFAULT_CANVAS_W,
                 canvas_h: int = DEFAULT_CANVAS_H,
                 parent=None):
        super().__init__(parent)
        self.canvas_name  = name
        self.delay_count  = 5

        self.scene = CanvasScene(canvas_w, canvas_h)
        self.view  = CanvasView(self.scene)

        self.palette_panel = PalettePanel()
        self.props_panel   = PropertiesPanel()
        self.preview_panel = PreviewPanel()
        self.layer_panel   = LayerPanel(self.scene)

        # Wire internal signals (selection / move / resize / prop change)
        self.scene.item_selected.connect(self.props_panel.load_item)
        self.scene.item_selected.connect(self.preview_panel.load_item)
        self.scene.item_moved.connect(self.props_panel.refresh_pos)
        self.scene.item_resized.connect(self.props_panel.refresh_pos)
        self.scene.item_resized.connect(lambda _: self.preview_panel.refresh())
        self.props_panel.property_changed.connect(self.preview_panel.refresh)
        self.scene.layers_changed.connect(
            lambda: QTimer.singleShot(0, self.layer_panel.refresh))
        self.scene.layers_changed.connect(
            lambda: QTimer.singleShot(0, lambda: self.props_panel.refresh_layer_combo(self.scene)))
        self.scene.item_added.connect(
            lambda: QTimer.singleShot(0, self.layer_panel.refresh))
        self.scene.item_removed.connect(
            lambda: QTimer.singleShot(0, self.layer_panel.refresh))

        # Canvas info banner
        self.canvas_info_lbl = QLabel()
        self.canvas_info_lbl.setAlignment(Qt.AlignCenter)
        self.canvas_info_lbl.setStyleSheet(
            "background:#252535; color:#888; font-size:10px; padding:2px;")
        self._update_canvas_info()

        # ── layout ─────────────────────────────────────────────────────────
        root = QHBoxLayout(self)
        root.setContentsMargins(0, 0, 0, 0)
        root.setSpacing(0)

        splitter = QSplitter(Qt.Horizontal)
        splitter.setChildrenCollapsible(False)

        splitter.addWidget(self.palette_panel)
        splitter.setStretchFactor(0, 0)

        canvas_wrap = QWidget()
        cv_layout = QVBoxLayout(canvas_wrap)
        cv_layout.setContentsMargins(0, 0, 0, 0)
        cv_layout.setSpacing(0)
        cv_layout.addWidget(self.canvas_info_lbl)
        cv_layout.addWidget(self.view)
        splitter.addWidget(canvas_wrap)
        splitter.setStretchFactor(1, 1)

        # Right panel: tabbed Properties / Value Preview / Layers
        right_tabs = QTabWidget()
        right_tabs.setDocumentMode(True)
        right_tabs.setStyleSheet("""
            QTabWidget::pane { border: none; }
            QTabBar::tab { padding: 4px 10px; font-size: 10px; }
        """)

        props_scroll = QScrollArea()
        props_scroll.setWidgetResizable(True)
        props_scroll.setWidget(self.props_panel)
        props_scroll.setMinimumWidth(230)
        right_tabs.addTab(props_scroll, "Properties")

        prev_scroll = QScrollArea()
        prev_scroll.setWidgetResizable(True)
        prev_scroll.setWidget(self.preview_panel)
        right_tabs.addTab(prev_scroll, "Value Preview")

        layer_scroll = QScrollArea()
        layer_scroll.setWidgetResizable(True)
        layer_scroll.setWidget(self.layer_panel)
        right_tabs.addTab(layer_scroll, "Layers")

        splitter.addWidget(right_tabs)
        splitter.setStretchFactor(2, 0)
        splitter.setSizes([160, 860, 260])

        root.addWidget(splitter)

    def _update_canvas_info(self):
        self.canvas_info_lbl.setText(
            f"Canvas: {self.scene.canvas_w} × {self.scene.canvas_h} px   "
            f"│  Items: {len(self.scene.items_only())}")


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Lacerta-HMI Designer")
        self.resize(1280, 780)
        self._build_menubar()
        self._build_toolbar()
        self._build_statusbar()
        self._build_backend()
        self._build_ui()

    # ── active tab helpers ─────────────────────────────────────────────────
    def _active_tab(self) -> Optional[CanvasTab]:
        if not hasattr(self, '_tabs') or self._tabs.count() == 0:
            return None
        w = self._tabs.currentWidget()
        return w if isinstance(w, CanvasTab) else None

    @property
    def scene(self):
        tab = self._active_tab()
        return tab.scene if tab else None

    @property
    def view(self):
        tab = self._active_tab()
        return tab.view if tab else None

    @property
    def props_panel(self):
        tab = self._active_tab()
        return tab.props_panel if tab else None

    @property
    def preview_panel(self):
        tab = self._active_tab()
        return tab.preview_panel if tab else None

    def _log(self, msg: str, color: str = "#c9d1d9"):
        """Append a timestamped message to the terminal panel."""
        ts = QDateTime.currentDateTime().toString("hh:mm:ss")
        self._log_view.append(
            f"<span style='color:#555'>[{ts}]</span> "
            f"<span style='color:{color}'>{msg}</span>"
        )

    def _build_backend(self):
        self.ser_loader = SerialLoader()
        self._was_connected = False
        self._clipboard: list = []   # snapshot dicts for Ctrl+C / Ctrl+V
        self._update_connect_btn()
        self._serial_check_timer = QTimer(self)
        self._serial_check_timer.setInterval(1000)
        self._serial_check_timer.timeout.connect(self._check_serial_connection)
        self._serial_check_timer.start()

    # ── UI scaffold ────────────────────────────────────────────────────────
    def _build_ui(self):
        self._stack = QStackedWidget()
        self.showMaximized()
        self.setCentralWidget(self._stack)

        # Page 0: welcome screen
        welcome = WelcomeWidget()
        welcome.new_canvas.connect(self._on_new_canvas)
        welcome.load_canvas.connect(self._on_load_canvas)
        self._stack.addWidget(welcome)

        # Page 1: tab widget
        self._tabs = QTabWidget()
        self._tabs.setTabsClosable(True)
        self._tabs.tabCloseRequested.connect(self._close_tab)
        self._tabs.currentChanged.connect(self._on_tab_switched)

        corner = QWidget()
        cl = QHBoxLayout(corner)
        cl.setContentsMargins(0, 2, 6, 2)
        cl.setSpacing(4)
        _tab_btn_style = (
            "QPushButton { background:#1e2a3a; color:#c9d1d9; border:1px solid #30363d;"
            " border-radius:4px; font-size:14px; padding:0 6px; }"
            "QPushButton:hover { background:#2d3f55; }"
        )
        btn_new = QPushButton("+")
        btn_new.setFixedHeight(24)
        btn_new.setMinimumWidth(28)
        btn_new.setToolTip("New canvas")
        btn_new.setStyleSheet(_tab_btn_style)
        btn_new.clicked.connect(self._on_new_canvas)
        btn_open = QPushButton("📁")
        btn_open.setFixedHeight(24)
        btn_open.setMinimumWidth(28)
        btn_open.setToolTip("Load scene from file")
        btn_open.setStyleSheet(_tab_btn_style)
        btn_open.clicked.connect(self._on_load_canvas)
        cl.addWidget(btn_new)
        cl.addWidget(btn_open)
        self._tabs.setCornerWidget(corner)

        self._stack.addWidget(self._tabs)
        self._toolbar.setEnabled(False)

        # ── Bottom terminal log panel ──────────────────────────────────────
        log_container = QWidget()
        log_container.setMaximumHeight(200)
        log_container.setMinimumHeight(80)
        log_layout = QVBoxLayout(log_container)
        log_layout.setContentsMargins(4, 2, 4, 2)
        log_layout.setSpacing(2)

        log_header = QHBoxLayout()
        log_header.setContentsMargins(0, 0, 0, 0)
        term_lbl = QLabel("Terminal")
        term_lbl.setStyleSheet("color:#888; font-size:11px; font-weight:bold;")
        clear_btn = QPushButton("Clear")
        clear_btn.setFixedHeight(18)
        clear_btn.setFixedWidth(50)
        clear_btn.setStyleSheet("QPushButton { font-size:10px; padding:0 4px; }")
        log_header.addWidget(term_lbl)
        log_header.addStretch()
        log_header.addWidget(clear_btn)

        self._log_view = QTextEdit()
        self._log_view.setReadOnly(True)
        self._log_view.setFont(QFont("Consolas", 9))
        self._log_view.setStyleSheet(
            "QTextEdit { background:#0d1117; color:#c9d1d9; border:1px solid #30363d; }"
        )
        clear_btn.clicked.connect(self._log_view.clear)

        log_layout.addLayout(log_header)
        log_layout.addWidget(self._log_view)

        main_splitter = QSplitter(Qt.Vertical)
        main_splitter.addWidget(self._stack)
        main_splitter.addWidget(log_container)
        main_splitter.setSizes([700, 140])
        main_splitter.setChildrenCollapsible(False)
        self.setCentralWidget(main_splitter)

    def _build_menubar(self):
        mb = self.menuBar()

        # File menu
        file_menu = mb.addMenu("&File")
        exit_act = QAction("E&xit", self)
        exit_act.setShortcut("Alt+F4")
        exit_act.triggered.connect(self.close)
        file_menu.addAction(exit_act)

        # Settings menu
        settings_menu = mb.addMenu("&Settings")
        tool_paths_act = QAction("Set &Tool Paths…", self)
        tool_paths_act.triggered.connect(self._on_set_tool_paths)
        settings_menu.addAction(tool_paths_act)

    def _on_set_tool_paths(self):
        dlg = SettingsDialog(self)
        if dlg.exec():
            # Re-run RISC-V toolchain check with the updated path
            self._riscv_dot.setStyleSheet("color: #888888;")
            self._riscv_dot.setToolTip("Checking RISC-V toolchain…")
            self._riscv_checker = RiscvCheckerThread(self)
            self._riscv_checker.done.connect(self._on_riscv_check_done)
            self._riscv_checker.start()

    def _build_toolbar(self):
        tb = QToolBar("Main")
        tb.setMovable(False)
        tb.setToolButtonStyle(Qt.ToolButtonIconOnly)
        tb.setIconSize(QSize(20,20))
        self.addToolBar(tb)
        self._toolbar = tb

        def act(lbl, slot, tip=""):
            a = QAction(lbl, self)
            a.setToolTip(tip)
            a.triggered.connect(slot)
            tb.addAction(a)
            return a

        act("🖼", self._dlg_canvas_size, "Canvas size")
        act("🎨", self._pick_canvas_color, "Canvas color")
        act("🌄", self._load_bg_image, "Load background image")
        act("🗑", self._clear_bg_image, "Clear background image")
        tb.addSeparator()
        act("➕",  lambda: self.view.zoom_in()   if self.view else None, "Zoom in (Ctrl+Wheel)")
        act("➖", lambda: self.view.zoom_out()  if self.view else None, "Zoom out (Ctrl+Wheel)")
        act("⬜",      lambda: self.view.fit_canvas() if self.view else None, "Fit canvas in view")
        tb.addSeparator()

        # Snap toggle
        self.snap_action = QAction("⊞ Snap", self)
        self.snap_action.setCheckable(True)
        self.snap_action.setChecked(True)
        self.snap_action.triggered.connect(self._toggle_snap)
        tb.addAction(self.snap_action)

        # Grid toggle
        self.grid_action = QAction("⊟ Grid", self)
        self.grid_action.setCheckable(True)
        self.grid_action.setChecked(True)
        self.grid_action.triggered.connect(self._toggle_grid)
        tb.addAction(self.grid_action)

        # Depth combo
        tb.addWidget(QLabel("Depth:"))
        self.depth_combo = QComboBox()
        self.depth_combo.addItems(["32", "24", "16", "8", "4", "2", "1"])
        self.depth_combo.setFixedHeight(26)
        self.depth_combo.setFixedWidth(60)
        self.depth_combo.currentTextChanged.connect(self._on_depth_changed)
        tb.addWidget(self.depth_combo)

        # HW representation checkbox
        tb.addWidget(QLabel("HW:"))
        self.hw_representation_checkbox = QCheckBox()
        self.hw_representation_checkbox.setToolTip("Show hardware RGB232 colour representation (R=2, G=3, B=2 bits)")
        self.hw_representation_checkbox.stateChanged.connect(self._on_hw_representation_changed)
        tb.addWidget(self.hw_representation_checkbox)

        # Grid size
        tb.addWidget(QLabel("Grid:"))
        self.grid_spin = GridSpinBox()
        self.grid_spin.setRange(5, 200)
        self.grid_spin.setValue(DEFAULT_GRID_SIZE)
        self.grid_spin.setMinimumWidth(40)
        self.grid_spin.setFixedHeight(26)
        self.grid_spin.valueChanged.connect(self._on_grid_size)
        tb.addWidget(self.grid_spin)

        # Delay count
        tb.addWidget(QLabel("Delay:"))
        self.delay_spin = QSpinBox()
        self.delay_spin.setRange(1, 9_999_999)
        self.delay_spin.setValue(5)
        self.delay_spin.setMinimumWidth(40)
        self.delay_spin.setFixedHeight(26)
        self.delay_spin.setToolTip("Firmware delay loop count (written to delay.S)")
        self.delay_spin.valueChanged.connect(self._on_delay_changed)
        tb.addWidget(self.delay_spin)

        tb.addSeparator()
        act("🗑️", self._delete_selected, "Delete selected indicator (Del)")
        act("🔃 All", self._clear_all, "Remove all indicators")
        tb.addSeparator()
        act("💾 Save", self._save_scene, "Save scene layout to JSON file")
        act("📁 Load", self._load_scene, "Load scene into current canvas from JSON file")
        act("⬆️ Export", self._export, "Export layout to JSON + images")

        tb.addSeparator()
        # COM serial combo
        tb.addWidget(QLabel("COM:"))
        self.com_combo = QComboBox()
        self.com_combo.setFixedHeight(26)
        self.com_combo.setFixedWidth(250)
        self.com_combo.currentTextChanged.connect(self._on_depth_changed)
        tb.addWidget(self.com_combo)
        act("🔃 Refresh", self._refresh_serial, "Refresh serial COM ports")
        self.connect_action = act("🔗 Connect", self._connect_serial, "Connect to selected serial COM")
        self._connect_btn = tb.widgetForAction(self.connect_action)
        self.upload_action = act("⬆️ Upload", self._upload_scene, "Load scene into FPGA")
        self.upload_action.setEnabled(False)

        self._upload_status_lbl = QLabel("")
        self._upload_status_lbl.setFixedWidth(22)
        self._upload_status_lbl.setAlignment(Qt.AlignCenter)
        self._upload_status_lbl.setStyleSheet("font-size:14px;")
        tb.addWidget(self._upload_status_lbl)

        self._spinner_frames = ["⣋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"]
        self._spinner_idx = 0
        self._spinner_timer = QTimer(self)
        self._spinner_timer.setInterval(80)
        self._spinner_timer.timeout.connect(self._spin_upload_icon)

        

    def _build_statusbar(self):
        sb = QStatusBar()
        sb.setStyleSheet("QStatusBar::item { border: none; }")
        self.setStatusBar(sb)

        self._canvas_name_lbl = QLabel()
        self._canvas_name_lbl.setStyleSheet("color: #AAAAAA; padding: 0 8px;")
        sb.addWidget(self._canvas_name_lbl)

        self._riscv_dot = QLabel("● RISC-V")
        self._riscv_dot.setStyleSheet("color: #888888;")
        self._riscv_dot.setToolTip("Checking RISC-V toolchain…")
        sb.addPermanentWidget(self._riscv_dot)

        self._riscv_checker = RiscvCheckerThread(self)
        self._riscv_checker.done.connect(self._on_riscv_check_done)
        self._riscv_checker.start()

    def _on_riscv_check_done(self, found: bool, message: str):
        if found:
            self._riscv_dot.setStyleSheet("color: #00CC44; font-size: 14px;")
            self._riscv_dot.setToolTip(message)
        else:
            self._riscv_dot.setStyleSheet("color: #CC2222; font-size: 14px;")
            self._riscv_dot.setToolTip(f"RISC-V toolchain not found\n{message}")

    # ── canvas status ──────────────────────────────────────────────────────
    def _update_status(self):
        tab = self._active_tab()
        if tab:
            self._canvas_name_lbl.setText(tab.canvas_name)
            tab._update_canvas_info()
        else:
            self._canvas_name_lbl.setText("")

    # ── canvas lifecycle ───────────────────────────────────────────────────
    def _on_new_canvas(self):
        name, ok = QInputDialog.getText(self, "New Canvas", "Canvas name:")
        name = name.strip()
        if ok and name:
            self._open_canvas(name)

    def _on_load_canvas(self):
        path, _ = QFileDialog.getOpenFileName(
            self, "Load Scene", _SCENES_DIR, "JSON Files (*.json)")
        if not path:
            return
        try:
            with open(path, "r") as f:
                data = json.load(f)
        except Exception as e:
            QMessageBox.critical(self, "Load Scene", f"Failed to read file:\n{e}")
            return
        items_data, bg_path, delay = _parse_scene_file(data, path)
        # Use parent folder name when file is named scene.json, otherwise stem
        fname = os.path.basename(path)
        name = os.path.basename(os.path.dirname(path)) if fname == "scene.json" else os.path.splitext(fname)[0]
        bg_pm = QPixmap(bg_path) if bg_path and os.path.isfile(bg_path) else None
        layers_data = data.get("layers") if isinstance(data, dict) else None
        self._open_canvas(name, scene_data=items_data, bg_pixmap=bg_pm,
                          delay_count=delay, layers_data=layers_data)

    def _open_canvas(self, name: str, scene_data=None, bg_pixmap=None,
                     delay_count=None, layers_data=None):
        from PySide6.QtCore import QTimer
        tab = CanvasTab(name)
        tab.scene.item_added.connect(self._update_status)
        tab.scene.item_removed.connect(self._update_status)
        if delay_count is not None:
            tab.delay_count = int(delay_count)
        if scene_data:
            _load_items_into_scene(tab.scene, scene_data)
            self._log(f"Loaded scene '{name}' ({len(scene_data)} item(s)).", "#61afef")
        else:
            self._log(f"Created new canvas '{name}'.", "#61afef")
        if bg_pixmap and not bg_pixmap.isNull():
            tab.scene.set_bg_image(bg_pixmap)
            self._log("Background image applied.", "#c678dd")
        # Restore layers
        if layers_data:
            tab.scene.layers = []
            for ld in layers_data:
                tab.scene.layers.append(Layer(ld["name"], ld.get("visible", True)))
            if not tab.scene.get_layer("default"):
                tab.scene.layers.insert(0, Layer("default"))
            tab.scene._sync_layer_visibility()
            tab.scene._sync_layer_z()
        idx = self._tabs.addTab(tab, name)
        self._tabs.setCurrentIndex(idx)
        self._stack.setCurrentIndex(1)
        self._toolbar.setEnabled(True)
        self._sync_toolbar_to_tab()
        self._update_status()
        QTimer.singleShot(50, tab.view.fit_canvas)

    def _close_tab(self, index: int):
        self._tabs.removeTab(index)
        if self._tabs.count() == 0:
            self._stack.setCurrentIndex(0)
            self._toolbar.setEnabled(False)
            self._canvas_name_lbl.setText("")

    def _on_tab_switched(self, _index: int):
        self._sync_toolbar_to_tab()
        self._update_upload_btn()
        self._update_status()

    def _sync_toolbar_to_tab(self):
        tab = self._active_tab()
        if not tab:
            return
        self.snap_action.setChecked(tab.scene.snap_enabled)
        self.snap_action.setText("⊞ Snap ON" if tab.scene.snap_enabled else "⊞ Snap OFF")
        self.grid_action.setChecked(tab.scene.show_grid)
        self.grid_action.setText("⊟ Grid ON" if tab.scene.show_grid else "⊟ Grid OFF")
        idx = self.depth_combo.findText(str(tab.scene.bit_depth))
        self.depth_combo.blockSignals(True)
        self.depth_combo.setCurrentIndex(idx if idx >= 0 else 0)
        self.depth_combo.blockSignals(False)
        self.grid_spin.blockSignals(True)
        self.grid_spin.setValue(tab.scene.grid_size)
        self.grid_spin.blockSignals(False)
        self.delay_spin.blockSignals(True)
        self.delay_spin.setValue(tab.delay_count)
        self.delay_spin.blockSignals(False)

    # ── keyboard shortcut ──────────────────────────────────────────────────
    def keyPressEvent(self, event):
        if event.key() == Qt.Key_Delete:
            self._delete_selected()
        elif event.modifiers() == Qt.ControlModifier:
            if event.key() == Qt.Key_C:
                self._copy_selected()
            elif event.key() == Qt.Key_V:
                self._paste_items()
            elif event.key() == Qt.Key_G:
                if self.scene:
                    self.scene.group_selected()
            else:
                super().keyPressEvent(event)
        elif event.modifiers() == (Qt.ControlModifier | Qt.ShiftModifier):
            if event.key() == Qt.Key_G:
                if self.scene:
                    self.scene.ungroup_selected()
            else:
                super().keyPressEvent(event)
        else:
            super().keyPressEvent(event)

    # ── toolbar slots ──────────────────────────────────────────────────────
    def _dlg_canvas_size(self):
        dlg = CanvasSizeDialog(self.scene.canvas_w, self.scene.canvas_h, self)
        if dlg.exec():
            w, h = dlg.values()
            self.scene.resize_canvas(w, h)
            self._update_status()

    def _pick_canvas_color(self):
        c = QColorDialog.getColor(self.scene.bg_color,
                                   self, "Canvas Background Color")
        if c.isValid():
            self.scene.bg_color = c
            self.scene._rebuild_depth_bg()
            self.scene.invalidate(self.scene.sceneRect(), QGraphicsScene.BackgroundLayer)

    def _load_bg_image(self):
        path, _ = QFileDialog.getOpenFileName(
            self, "Load Background Image", "",
            "Images (*.png *.jpg *.jpeg *.bmp *.gif *.webp *.tiff)"
        )
        if not path:
            return
        pm = QPixmap(path)
        if pm.isNull():
            QMessageBox.warning(self, "Load Background Image",
                                "Could not load image file.")
            return
        self.scene.set_bg_image(pm)
        fname = os.path.basename(path)
        self._log(f"Background image loaded: {fname}", "#c678dd")

    def _clear_bg_image(self):
        if self.scene is None:
            return
        has_bg = self.scene.bg_image is not None and not self.scene.bg_image.isNull()
        if not has_bg:
            return
        self.scene.set_bg_image(QPixmap())
        self._log("Background image cleared.", "#c678dd")

        # Remove saved bg files from scenes/ folder
        tab = self._active_tab()
        if tab:
            scene_dir = os.path.join(_SCENES_DIR, tab.canvas_name)
            for fname in ("bg.png", "bg.jpg", "bg.bmp"):
                fpath = os.path.join(scene_dir, fname)
                if os.path.isfile(fpath):
                    try:
                        os.remove(fpath)
                        self._log(f"Removed {os.path.join('scenes', tab.canvas_name, fname)}", "#888")
                    except OSError as e:
                        self._log(f"Could not remove {fname}: {e}", "#e5c07b")

    def _toggle_snap(self, checked: bool):
        self.scene.snap_enabled = checked
        self.snap_action.setText("⊞ Snap ON" if checked else "⊞ Snap OFF")

    def _toggle_grid(self, checked: bool):
        self.scene.show_grid = checked
        self.grid_action.setText("⊟ Grid ON" if checked else "⊟ Grid OFF")
        self.scene.invalidate(self.scene.sceneRect(), QGraphicsScene.BackgroundLayer)

    def _on_grid_size(self, val: int):
        self.scene.grid_size = val
        self.scene.update()

    def _on_delay_changed(self, val: int):
        tab = self._active_tab()
        if tab:
            tab.delay_count = val

    def _on_depth_changed(self, text: str):
        self.scene.bit_depth = int(text)   # setter rebuilds bg cache + invalidates
        self.scene.update()
        self.preview_panel.refresh()

    def _on_hw_representation_changed(self, state: int):
        self.scene.hw_mode = bool(state)
        self.preview_panel.refresh()

    def _delete_selected(self):
        items = [i for i in self.scene.selectedItems()
                 if isinstance(i, (IndicatorItem, GroupItem))
                 and i.parentItem() is None]
        if not items:
            return
        n_ind = sum(1 for i in items if isinstance(i, IndicatorItem))
        n_grp = sum(1 for i in items if isinstance(i, GroupItem))
        parts = []
        if n_ind:
            parts.append(f"{n_ind} indicator{'s' if n_ind > 1 else ''}")
        if n_grp:
            parts.append(f"{n_grp} group{'s' if n_grp > 1 else ''}")
        noun = " and ".join(parts)
        ret = QMessageBox.question(
            self, "Delete",
            f"Remove {noun} from the canvas?",
            QMessageBox.Yes | QMessageBox.No,
        )
        if ret == QMessageBox.Yes:
            for item in items:
                self.scene.removeItem(item)
            self._update_status()

    _PASTE_OFFSET = 24   # pixels to cascade each paste

    def _copy_selected(self):
        if not self.scene:
            return
        items = [i for i in self.scene.selectedItems() if isinstance(i, IndicatorItem)]
        if not items:
            return
        self._clipboard = [
            {
                'obj_type': i.obj_type,
                'x': i.pos().x(), 'y': i.pos().y(),
                'w': i.obj_w, 'h': i.obj_h,
                'color': i.color.name(),
                'min_val': i.min_val, 'max_val': i.max_val,
                'seg_italic': i.seg_italic,
                'seg_hex_mode': i.seg_hex_mode,
                'static_text': i.static_text,
                'font_family': i.font_family,
                'unit_label': i.unit_label,
                'decimal_places': i.decimal_places,
                '_preview_fraction': i._preview_fraction,
            }
            for i in items
        ]
        self._log(f"Copied {len(items)} indicator(s).", "#888888")

    def _paste_items(self):
        if not self._clipboard or not self.scene:
            return
        off = self._PASTE_OFFSET
        self.scene.clearSelection()
        for snap in self._clipboard:
            item = IndicatorItem(
                snap['obj_type'],
                snap['x'] + off, snap['y'] + off,
                snap['w'], snap['h'],
                color=QColor(snap['color']),
            )
            item.min_val           = snap['min_val']
            item.max_val           = snap['max_val']
            item.seg_italic        = snap['seg_italic']
            item.seg_hex_mode      = snap['seg_hex_mode']
            item.static_text       = snap.get('static_text', '')
            item.font_family       = snap.get('font_family', 'Segoe UI')
            item.unit_label        = snap.get('unit_label', '')
            item.decimal_places    = snap.get('decimal_places', 1)
            item._preview_fraction = snap['_preview_fraction']
            self.scene.addItem(item)
            item.setSelected(True)
        self.scene.item_added.emit()
        self._log(f"Pasted {len(self._clipboard)} indicator(s).", "#888888")
        # Shift clipboard so repeated Ctrl+V cascades items diagonally
        for snap in self._clipboard:
            snap['x'] += off
            snap['y'] += off

    def _clear_all(self):
        ret = QMessageBox.question(self, "Clear All",
                                   "Remove all indicators from the canvas?",
                                   QMessageBox.Yes | QMessageBox.No)
        if ret == QMessageBox.Yes:
            for item in self.scene.top_level_items():
                self.scene.removeItem(item)
            IndicatorItem._id_counter = 0
            GroupItem._counter = 0
            self._update_status()

    def _save_scene(self):
        top_items = self.scene.top_level_items()
        if not top_items:
            QMessageBox.information(self, "Save Scene", "No indicators to save.")
            return

        tab = self._active_tab()
        canvas_name = tab.canvas_name if tab else "untitled"

        scene_dir = os.path.join(_SCENES_DIR, canvas_name)
        os.makedirs(scene_dir, exist_ok=True)

        payload = {}

        # Save bg image alongside if present
        has_bg = self.scene.bg_image is not None and not self.scene.bg_image.isNull()
        if has_bg:
            bg_out = os.path.join(scene_dir, "bg.png")
            self.scene.bg_image.save(bg_out, "PNG")
            payload["bg_image"] = "bg.png"

        payload["delay_count"] = tab.delay_count if tab else 5

        payload["layers"] = [
            {"name": l.name, "visible": l.visible}
            for l in self.scene.layers
        ]

        payload["items"] = [
            _serialize_item(item) for item in self.scene.top_level_items()
        ]

        json_path = os.path.join(scene_dir, "scene.json")
        with open(json_path, "w") as f:
            json.dump(payload, f, indent=2)

        self._log(f"Scene '{canvas_name}' saved to scenes/{canvas_name}/", "#98c379")
        QMessageBox.information(self, "Save Scene", f"Scene saved to:\nscenes/{canvas_name}/")

    def _load_scene(self):
        """Load scene from JSON into the current active canvas (adds, skips duplicates)."""
        path, _ = QFileDialog.getOpenFileName(
            self, "Load Scene", _SCENES_DIR, "JSON Files (*.json)"
        )
        if not path:
            return
        try:
            with open(path, "r") as f:
                data = json.load(f)
        except Exception as e:
            QMessageBox.critical(self, "Load Scene", f"Failed to read file:\n{e}")
            return

        items_data, bg_path, delay, layers_data = _parse_scene_file(data, path)
        # Restore layers: rebuild the list to match saved order, preserving existing layers
        if layers_data:
            saved_names = [e.get("name", "") for e in layers_data if e.get("name")]
            saved_vis   = {e["name"]: e.get("visible", True) for e in layers_data if e.get("name")}
            # Add any saved layers that don't exist yet (keeps existing ones)
            for name in saved_names:
                if not self.scene.get_layer(name):
                    self.scene.add_layer(name)
            # Re-order scene.layers to match saved order; unsaved layers go at the end
            ordered = []
            for name in saved_names:
                lyr = self.scene.get_layer(name)
                if lyr:
                    lyr.visible = saved_vis.get(name, True)
                    ordered.append(lyr)
            for lyr in self.scene.layers:
                if lyr not in ordered:
                    ordered.append(lyr)
            self.scene.layers = ordered
            self.scene._sync_layer_visibility()
            self.scene._sync_layer_z()
            self.scene.layers_changed.emit()
        before = len(self.scene.items_only())
        _load_items_into_scene(self.scene, items_data)
        self.scene._sync_layer_z()
        self.scene._sync_layer_visibility()
        added = len(self.scene.items_only()) - before
        if bg_path and os.path.isfile(bg_path):
            pm = QPixmap(bg_path)
            if not pm.isNull():
                self.scene.set_bg_image(pm)
        if delay is not None:
            tab = self._active_tab()
            if tab:
                tab.delay_count = int(delay)
                self.delay_spin.setValue(tab.delay_count)
        QMessageBox.information(self, "Load Scene", f"Loaded {added} indicator(s).")

    def _export(self):
        items = self.scene.items_only()
        if not items:
            QMessageBox.information(self, "Export", "No indicators to export.")
            return

        bit_depth = self.scene.bit_depth

        tab = self._active_tab()
        canvas_name = tab.canvas_name if tab else "untitled"
        out_dir = os.path.join(os.getcwd(), "output", canvas_name)
        os.makedirs(out_dir, exist_ok=True)
        self._log(f"Exporting canvas '{canvas_name}' ({len(items)} item(s))…", "#e5c07b")

        # Save current state
        state = {item: item._preview_fraction for item in items}
        
        # Hide selection boxes & handles during render
        self.scene.clearSelection()
        self.scene._exporting = True

        def render_scene(filename):
            # Render exactly the canvas rect area (the drawing board)
            rect = QRectF(self.scene.canvas_x, self.scene.canvas_y, self.scene.canvas_w, self.scene.canvas_h)
            img = QImage(int(rect.width()), int(rect.height()), QImage.Format_ARGB32)
            img.fill(self.scene.bg_color)
            painter = QPainter(img)
            painter.setRenderHint(QPainter.Antialiasing)
            painter.translate(-rect.left(), -rect.top())
            self.scene.render(painter, rect, rect)
            painter.end()

            # Stage 1: selected bit-depth quantization (passthrough for 32/24)
            if bit_depth not in (32, 24):
                img = _quantize_qimage(img, bit_depth)
            else:
                img = img.convertToFormat(QImage.Format_RGB888)

            # Stage 2: always apply RGB232 hardware quantization for export
            img = _quantize_qimage(img, 7)

            img.save(os.path.join(out_dir, filename))

        # Empty state
        for item in items:
            item._preview_fraction = -1.0 if item.obj_type == "seven_seg" else 0.0
            item.update()
        QApplication.processEvents()
        render_scene("frame_empty.png")

        for item in items:
            if item.obj_type == "seven_seg" and not item.seg_hex_mode:
                item._preview_fraction = 8.0 / 9.0  # Force '8' exactly
            elif item.obj_type == "graph":
                item._preview_fraction = 0.5         # mid-scale is most visible
            else:
                item._preview_fraction = 1.0
            item.update()
        QApplication.processEvents()
        render_scene("frame_full.png")

        # Write frame_full.bin: 0RRGGGBB encoding of what will be sent over serial
        ff_png_path = os.path.join(out_dir, "frame_full.png")
        ff_bin_path = os.path.join(out_dir, "frame_full.bin")
        with Image.open(ff_png_path) as pil_ff:
            rgb_ff = pil_ff.convert('RGB').resize((640, 480), Image.LANCZOS)
            with open(ff_bin_path, 'w') as bf:
                for _y in range(480):
                    for _x in range(640):
                        r, g, b = rgb_ff.getpixel((_x, _y))
                        packed = ((r >> 6) << 5) | ((g >> 5) << 2) | (b >> 6)
                        bf.write(f"{packed:08b}\n")

        # Restore state
        for item in items:
            item._preview_fraction = state[item]
            item.update()
        
        self.scene._exporting = False
        self.scene.update()

        # Build JSON
        objects = []
        for item in sorted(items, key=lambda i: i.item_id):
            p = item.st_pix()
            objects.append({
                "uid": f"uid_{item.item_id}",
                "obj_type": item.obj_type,
                "label": item.label,
                "width": int(item.obj_w),
                "height": int(item.obj_h),
                "x": int(p[0]),
                "y": int(p[1])
            })

        json_path = os.path.join(out_dir, "scene.json")
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(objects, f, indent=2)

        # Export background image
        bg_jpg_path = os.path.join(out_dir, "bg.jpg")
        bg_bin_path = os.path.join(out_dir, "bg.bin")
        has_bg = self.scene.bg_image is not None and not self.scene.bg_image.isNull()
        if has_bg:
            scaled = self.scene.bg_image.scaled(
                self.scene.canvas_w, self.scene.canvas_h,
                Qt.IgnoreAspectRatio, Qt.SmoothTransformation,
            )
            scaled.save(bg_jpg_path, "JPEG")
            with Image.open(bg_jpg_path) as pil_img:
                gray_img = pil_img.convert('L').resize((640, 480), Image.LANCZOS)
                with open(bg_bin_path, 'w') as bf:
                    for _y in range(480):
                        for _x in range(640):
                            gray = gray_img.getpixel((_x, _y))
                            bf.write(f"{gray >> 3:05b}\n")

        # Compile RISC-V firmware
        fw_items = [
            {"obj_type": item.obj_type,
             "width":    int(item.obj_w),
             "height":   int(item.obj_h),
             "x":        int(p[0]),
             "y":        int(p[1])+ int(item.obj_h)}
            for item in sorted(items, key=lambda i: i.item_id)
            for p in [item.st_pix()]
        ]
        fw_ok, fw_msg = _build_firmware(canvas_name, fw_items, out_dir,
                                        delay_count=tab.delay_count if tab else 5,
                                        gcc_exe=_riscv_gcc_exe(),
                                        log_fn=self._log)

        bg_note = "\n- bg.jpg\n- bg.bin" if has_bg else ""
        if fw_ok:
            self._log(f"Export complete: output/{canvas_name}/  Firmware OK.", "#98c379")
            QMessageBox.information(
                self, "Export Complete",
                f"Exported to:\noutput/{canvas_name}/\n\n"
                f"- frame_empty.png\n- frame_full.png\n- frame_full.bin\n- scene.json{bg_note}\n\n"
                f"Firmware:\n{fw_msg}")
        else:
            self._log(f"Export done (firmware error): output/{canvas_name}/", "#e5c07b")
            QMessageBox.warning(
                self, "Export Complete (firmware error)",
                f"Images and scene.json exported to:\noutput/{canvas_name}/{bg_note}\n\n"
                f"Firmware build failed:\n{fw_msg}")
        self._update_upload_btn()

    def _update_upload_btn(self):
        """Enable upload only when exported AND connected (and no upload running)."""
        if self._spinner_timer.isActive():
            return  # keep disabled while upload is in progress
        tab = self._active_tab()
        if not tab or not self.ser_loader.is_connected:
            self.upload_action.setEnabled(False)
            return
        out_dir = os.path.join(os.getcwd(), "output", tab.canvas_name)
        exported = os.path.isfile(os.path.join(out_dir, "frame_empty.png"))
        self.upload_action.setEnabled(exported)

    def _spin_upload_icon(self):
        self._upload_status_lbl.setText(self._spinner_frames[self._spinner_idx % len(self._spinner_frames)])
        self._spinner_idx += 1

    def _on_upload_finished(self, success: bool, error: str):
        self._spinner_timer.stop()
        if success:
            self._upload_status_lbl.setText("✅")
            self._log("Upload complete.", "#98c379")
        else:
            self._upload_status_lbl.setText("❌")
            self._log(f"Upload failed: {error}", "#e06c75")
        QTimer.singleShot(3000, self._reset_upload_status)

    def _reset_upload_status(self):
        self._upload_status_lbl.setText("")
        self._update_upload_btn()

    def _update_connect_btn(self):
        connected = self.ser_loader.is_connected
        if connected:
            self.connect_action.setText("⛔ Disconnect")
            self.connect_action.setToolTip("Disconnect from serial COM")
            self._connect_btn.setStyleSheet(
                "QToolButton { background:#7A0000; color:#FFFFFF; border-radius:4px; padding:4px 8px; }"
                "QToolButton:hover { background:#AA0000; }"
            )
        else:
            self.connect_action.setText("🔗 Connect")
            self.connect_action.setToolTip("Connect to selected serial COM")
            self._connect_btn.setStyleSheet(
                "QToolButton { background:#1A4A1A; color:#FFFFFF; border-radius:4px; padding:4px 8px; }"
                "QToolButton:hover { background:#2A7A2A; }"
            )

    def _check_serial_connection(self):
        """Periodic check – update button if an open port was lost unexpectedly."""
        connected = self.ser_loader.is_connected
        if not connected:
            self._update_connect_btn()
        if self._was_connected and not connected:
            self._log("Serial port disconnected unexpectedly.", "#e06c75")
            self._update_upload_btn()
        self._was_connected = connected

    def _refresh_serial(self):

        ports = serial.tools.list_ports.comports()

        self.com_combo.clear()

        for port in ports:
            name = f"{port.device} ({port.description})"
            self.com_combo.addItem(name, port.device)

    def _connect_serial(self):
        if self.ser_loader.is_connected:
            port = self.com_combo.currentData() or "port"
            self.ser_loader.disconnect()
            self._update_connect_btn()
            self._update_upload_btn()
            self._log(f"Disconnected from {port}.", "#e06c75")
            return

        port = self.com_combo.currentData()

        if not port:
            self._log("No COM port selected.", "#e5c07b")
            return

        self.ser_loader.connect(port)
        self._update_connect_btn()
        self._update_upload_btn()
        if self.ser_loader.is_connected:
            self._log(f"Connected to {port}.", "#98c379")
        else:
            self._log(f"Failed to connect to {port}.", "#e06c75")

    def _upload_scene(self):
        tab = self._active_tab()
        canvas_name = tab.canvas_name if tab else "untitled"
        out_dir = os.path.join(os.getcwd(), "output", canvas_name)

        self.ser_loader.set_paths(
            masks_path="tools/masks/",
            instruction_path=os.path.join(out_dir, f"{canvas_name}_be.hex"),
            bg_img_path=os.path.join(out_dir, "frame_full.png"),
        )

        has_bg = self.scene.bg_image is not None and not self.scene.bg_image.isNull()

        self.upload_action.setEnabled(False)
        self._upload_status_lbl.setText(self._spinner_frames[0])
        self._spinner_idx = 1
        self._spinner_timer.start()

        self._upload_worker = UploadWorker(
            self.ser_loader, canvas_name, out_dir, has_bg, parent=self
        )
        self._upload_worker.log.connect(self._log)
        self._upload_worker.finished.connect(self._on_upload_finished)
        self._upload_worker.start()


# ─────────────────────────────────────────────
#  ENTRY POINT
# ─────────────────────────────────────────────

def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Lacerta-HMI Designer")
    app.setStyleSheet(APP_STYLE)

    window = MainWindow()
    window.show()

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
