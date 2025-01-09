%dw 2.0

import cos, logn, E, PI from dw::util::Math
fun boxMullerNormal(): Number = do {
    var uniform1 = random()
    var logUniform1 = logn(uniform1)
    var logFactor1: Number = if (logUniform1 is NaN) logn(10e-10) as Number else logUniform1
    var uniform2 = random()
    ---
    sqrt(-2 * logFactor1) * cos(2 * PI * uniform2)
}

fun gaussian(): Number = boxMullerNormal()

fun logNormal(): Number = do {
    var normalRandom = boxMullerNormal()
    ---
    if (normalRandom == 0) 1
    else if (normalRandom < 0) 1 / (E pow (-1 * normalRandom))
    else (E pow normalRandom)
}

@TailRec()
fun logNormalCapped(maximum: Number): Number = do {
    var candidate = logNormal()
    ---
    if (candidate < maximum) candidate
    else logNormalCapped(maximum)
}