package com.evao.e0.picmerge

private const val HEX = "0123456789ABCDEF"
private const val UNRESERVED = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"

/** 메일 앱을 열 `mailto:` URI. 제목은 RFC 3986의 비예약 문자만 남기고 UTF-8로 퍼센트 인코딩한다. */
internal fun mailtoUri(to: String, subject: String): String {
    val encoded = StringBuilder()
    for (byte in subject.toByteArray(Charsets.UTF_8)) {
        val value = byte.toInt() and 0xFF
        val char = value.toChar()
        if (value < 0x80 && char in UNRESERVED) {
            encoded.append(char)
        } else {
            encoded.append('%').append(HEX[value shr 4]).append(HEX[value and 0xF])
        }
    }
    return "mailto:$to?subject=$encoded"
}
