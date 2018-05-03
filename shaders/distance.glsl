/**
 * 2D distance functions to geometry.
 */

/**
 * @requires trigonometry
 */

float circleDist(vec2 pos, vec2 point, float size) {
    return distance(pos, point)/size;
}

float circleDist2(vec2 pos, vec2 point, float size) {
    return distance2(pos, point)/(size*size);
}


float nearestAlongLine(vec2 pos, Ray2 line, float lineLength) {
    return clamp(dot(line.direction, pos-line.point), 0.0, lineLength);
}

vec2 nearestOnLine(vec2 pos, Ray2 line, float lineLength) {
    return line.point+(line.direction*nearestAlongLine(pos, line, lineLength));
}

float angleDist(vec2 pos, Ray2 line, float l, float w, float dotLimit) {
    vec2 lineTip = line.point+(line.direction*(l+w)),
        tipToPos = pos-lineTip;

    float normLimit = 1.0+dotLimit,
        norm = 2.0-normLimit;

    return (1.0+dot(normalize(tipToPos), -line.direction)-normLimit)/norm;
}

// This is probably meaningless...
float angleDist2(vec2 pos, Ray2 line, float l, float w, float dotLimit) {
    vec2 lineTip = line.point+(line.direction*(l+w)),
        reverse = -line.direction,
        tipToPos = pos-lineTip;

    float normLimit = 1.0+dotLimit,
        norm = 2.0-normLimit,
        l2 = length2(tipToPos);

    return (1.0+dot(tipToPos/l2, reverse)-normLimit)/norm;
}

float lineDist(vec2 pos, Ray2 line, float l, float w, out vec2 nearest) {
    nearest = nearestOnLine(pos, line, l);

    return circleDist(pos, nearest, w);
}

float lineDist2(vec2 pos, Ray2 line, float l, float w, out vec2 nearest) {
    nearest = nearestOnLine(pos, line, l);

    return circleDist2(pos, nearest, w);
}
