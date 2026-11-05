package com.evao.e0.picmerge

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * [CropBox.toRaw]가 실제 EXIF 회전과 맞는지 확인한다.
 * 칸마다 번호를 매긴 작은 원본을 EXIF 규칙대로 돌린 화면 격자에서 영역을 고르고,
 * 같은 영역을 toRaw로 원본에서 잘랐을 때 같은 칸들이 나오는지 비교한다.
 */
class CropBoxTest {
    private val rawW = 4
    private val rawH = 3

    private fun raw(x: Int, y: Int) = y * rawW + x

    /** EXIF 정의대로 원본을 화면 방향 격자로 만든다. 결과는 [행][열]. */
    private fun oriented(orientation: Int): List<List<Int>> {
        val swapped = orientation in 5..8
        val w = if (swapped) rawH else rawW
        val h = if (swapped) rawW else rawH
        return List(h) { y ->
            List(w) { x ->
                when (orientation) {
                    2 -> raw(rawW - 1 - x, y) // 좌우 반전
                    3 -> raw(rawW - 1 - x, rawH - 1 - y) // 180도
                    4 -> raw(x, rawH - 1 - y) // 상하 반전
                    5 -> raw(y, x) // transpose
                    6 -> raw(y, rawH - 1 - x) // 표시하려면 시계 방향 90도
                    7 -> raw(rawW - 1 - y, rawH - 1 - x) // transverse
                    8 -> raw(rawW - 1 - y, x) // 표시하려면 반시계 방향 90도
                    else -> raw(x, y)
                }
            }
        }
    }

    private fun cellsOriented(grid: List<List<Int>>, c: CropBox): Set<Int> {
        val h = grid.size
        val w = grid[0].size
        val out = mutableSetOf<Int>()
        for (y in (c.top * h).toInt() until (c.bottom * h).toInt()) {
            for (x in (c.left * w).toInt() until (c.right * w).toInt()) out.add(grid[y][x])
        }
        return out
    }

    private fun cellsRaw(c: CropBox): Set<Int> {
        val out = mutableSetOf<Int>()
        for (y in Math.round(c.top * rawH).toInt() until Math.round(c.bottom * rawH).toInt()) {
            for (x in Math.round(c.left * rawW).toInt() until Math.round(c.right * rawW).toInt()) out.add(raw(x, y))
        }
        return out
    }

    @Test
    fun `모든 EXIF 방향에서 고른 영역과 원본에서 자른 영역이 같은 칸이다`() {
        for (orientation in 1..8) {
            val grid = oriented(orientation)
            val h = grid.size
            val w = grid[0].size
            // 화면 격자의 칸 경계에 맞춘 모든 사각형을 시험한다.
            for (l in 0 until w) for (r in l + 1..w) for (t in 0 until h) for (b in t + 1..h) {
                val box = CropBox(l.toDouble() / w, t.toDouble() / h, r.toDouble() / w, b.toDouble() / h)
                assertEquals(
                    "orientation=$orientation box=$box",
                    cellsOriented(grid, box),
                    cellsRaw(box.toRaw(orientation)),
                )
            }
        }
    }

    @Test
    fun `전체 영역은 어느 방향이든 전체 영역이다`() {
        for (orientation in 0..8) assertEquals(CropBox.FULL, CropBox.FULL.toRaw(orientation))
    }

    @Test
    fun `폭과 높이`() {
        val box = CropBox(0.25, 0.1, 0.75, 0.6)
        assertEquals(0.5, box.width, 1e-9)
        assertEquals(0.5, box.height, 1e-9)
    }
}
