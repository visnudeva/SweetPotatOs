// SPDX-License-Identifier: GPL-3.0-or-later

export const MASK_MODES = {
    CIRCLE: 'circle',
    TRIANGLE_UP: 'triangle-up',
    TRIANGLE_DOWN: 'triangle-down',
    DIAMOND: 'diamond',
    HEXAGON: 'hexagon',
    RECTANGLE_VERTICAL: 'rectangle-vertical',
    RECTANGLE_HORIZONTAL: 'rectangle-horizontal',
    WIDE: 'wide',
};

export function getCentralAreaDivisor(width) {
    return width > 768 ? 3 : 4.5;
}

export function getMaskRadius(height, width) {
    return height / getCentralAreaDivisor(width);
}

function _sign(px, py, x1, y1, x2, y2) {
    return (px - x2) * (y1 - y2) - (x1 - x2) * (py - y2);
}

function _pointInTriangle(px, py, x1, y1, x2, y2, x3, y3) {
    const d1 = _sign(px, py, x1, y1, x2, y2);
    const d2 = _sign(px, py, x2, y2, x3, y3);
    const d3 = _sign(px, py, x3, y3, x1, y1);
    const hasNeg = d1 < 0 || d2 < 0 || d3 < 0;
    const hasPos = d1 > 0 || d2 > 0 || d3 > 0;
    return !(hasNeg && hasPos);
}

function _pointInPolygon(px, py, vertices) {
    let inside = false;

    for (let i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
        const [xi, yi] = vertices[i];
        const [xj, yj] = vertices[j];

        if (((yi > py) !== (yj > py)) &&
            px < (xj - xi) * (py - yi) / (yj - yi) + xi)
            inside = !inside;
    }

    return inside;
}

function _regularPolygonVertices(cx, cy, radius, sides, startAngle = -Math.PI / 2) {
    const vertices = [];

    for (let i = 0; i < sides; i++) {
        const angle = startAngle + i * (2 * Math.PI / sides);
        vertices.push([
            cx + radius * Math.cos(angle),
            cy + radius * Math.sin(angle),
        ]);
    }

    return vertices;
}

function _pointInDiamond(px, py, cx, cy, radius) {
    return Math.abs(px - cx) + Math.abs(py - cy) < radius;
}

function _pointInRectangle(px, py, cx, cy, halfWidth, halfHeight) {
    return Math.abs(px - cx) <= halfWidth && Math.abs(py - cy) <= halfHeight;
}

export function isInsideMask(x, y, width, height, mode) {
    if (mode === MASK_MODES.WIDE || mode === 'none')
        return true;

    const cx = width / 2;
    const cy = height / 2;
    const radius = getMaskRadius(height, width);

    switch (mode) {
    case MASK_MODES.TRIANGLE_UP:
        return _pointInTriangle(
            x, y,
            cx, cy - radius,
            cx - radius, cy + radius,
            cx + radius, cy + radius,
        );
    case MASK_MODES.TRIANGLE_DOWN:
        return _pointInTriangle(
            x, y,
            cx, cy + radius,
            cx - radius, cy - radius,
            cx + radius, cy - radius,
        );
    case MASK_MODES.DIAMOND:
        return _pointInDiamond(x, y, cx, cy, radius);
    case MASK_MODES.HEXAGON:
        return _pointInPolygon(
            x, y,
            _regularPolygonVertices(cx, cy, radius, 6),
        );
    case MASK_MODES.RECTANGLE_VERTICAL:
        return _pointInRectangle(x, y, cx, cy, radius * 0.5, radius);
    case MASK_MODES.RECTANGLE_HORIZONTAL:
        return _pointInRectangle(x, y, cx, cy, radius, radius * 0.5);
    default:
        return Math.hypot(x - cx, y - cy) < radius;
    }
}

export function getOverlayGeometry(monitor, mode) {
    if (mode === MASK_MODES.WIDE || mode === 'none') {
        return {
            x: monitor.x,
            y: monitor.y,
            width: monitor.width,
            height: monitor.height,
        };
    }

    const radius = getMaskRadius(monitor.height, monitor.width);
    const size = radius * 2;

    return {
        x: monitor.x + (monitor.width - size) / 2,
        y: monitor.y + (monitor.height - size) / 2,
        width: size,
        height: size,
    };
}
