// SPDX-License-Identifier: GPL-3.0-or-later

export const MASK_MODE_LABELS = [
    'Circle',
    'Triangle up',
    'Triangle down',
    'Diamond',
    'Hexagon',
    'Vertical rectangle',
    'Horizontal rectangle',
    'Wide',
];

export const MASK_MODE_VALUES = [
    'circle',
    'triangle-up',
    'triangle-down',
    'diamond',
    'hexagon',
    'rectangle-vertical',
    'rectangle-horizontal',
    'wide',
];

export function normalizeMaskMode(value, fallback = 'circle') {
    if (value === 'none')
        return 'wide';

    if (!value || !MASK_MODE_VALUES.includes(value))
        return fallback;

    return value;
}

export function maskModeIndex(value) {
    return MASK_MODE_VALUES.indexOf(normalizeMaskMode(value));
}
