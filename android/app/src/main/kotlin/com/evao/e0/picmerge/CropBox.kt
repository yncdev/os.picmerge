package com.evao.e0.picmerge

/** 영역 편집 결과. 0~1 비율 좌표다 (DESIGN §2.1.6). Android 클래스에 의존하지 않아 JVM에서 테스트한다. */
data class CropBox(val left: Double, val top: Double, val right: Double, val bottom: Double) {
    val width: Double get() = right - left
    val height: Double get() = bottom - top

    /**
     * EXIF 회전을 반영한 좌표(화면에서 고른 영역)를 디코딩 전 원본 좌표로 바꾼다.
     * [orientation]은 EXIF 방향 값(1~8)이다. 각 값은 화면 좌표 (x', y')가 원본의 어디에서 왔는지로 정한다.
     */
    fun toRaw(orientation: Int): CropBox = when (orientation) {
        2 -> CropBox(1 - right, top, 1 - left, bottom) // 좌우 반전: x = 1 - x', y = y'
        3 -> CropBox(1 - right, 1 - bottom, 1 - left, 1 - top) // 180도: x = 1 - x', y = 1 - y'
        4 -> CropBox(left, 1 - bottom, right, 1 - top) // 상하 반전: x = x', y = 1 - y'
        5 -> CropBox(top, left, bottom, right) // transpose: x = y', y = x'
        6 -> CropBox(top, 1 - right, bottom, 1 - left) // 시계 방향 90도: x = y', y = 1 - x'
        7 -> CropBox(1 - bottom, 1 - right, 1 - top, 1 - left) // transverse: x = 1 - y', y = 1 - x'
        8 -> CropBox(1 - bottom, left, 1 - top, right) // 반시계 방향 90도: x = 1 - y', y = x'
        else -> this
    }

    companion object {
        val FULL = CropBox(0.0, 0.0, 1.0, 1.0)
    }
}
