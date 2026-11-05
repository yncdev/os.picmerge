package com.evao.e0.picmerge

import org.junit.Assert.assertEquals
import org.junit.Test

/** 문자열만 만든다. 메일 앱을 열지 않는다. */
class MailtoUriTest {
    @Test
    fun encodesTheFeedbackSubject() {
        assertEquals(
            "mailto:yncdev@gmail.com?subject=Pic%20Merge%20inquiry%20-%20App%3A%20Pic%20Merge%201.0.0%20%281%29" +
                "%2C%20Device%3A%20samsung%20SM-S938N%2C%20OS%3A%20Android%2017",
            mailtoUri(
                "yncdev@gmail.com",
                "Pic Merge inquiry - App: Pic Merge 1.0.0 (1), Device: samsung SM-S938N, OS: Android 17",
            ),
        )
    }

    @Test
    fun encodesCharactersThatWouldBreakTheQuery() {
        assertEquals("mailto:a@b.c?subject=x%26y%3Dz%2B1%3F%23", mailtoUri("a@b.c", "x&y=z+1?#"))
    }

    @Test
    fun encodesNonAsciiAsUtf8() {
        assertEquals("mailto:a@b.c?subject=%C3%A9", mailtoUri("a@b.c", "é"))
    }

    @Test
    fun keepsUnreservedCharacters() {
        assertEquals("mailto:a@b.c?subject=aZ0-._~", mailtoUri("a@b.c", "aZ0-._~"))
    }
}
