/**
 * Generate the snowflake shape and surface. Refract through to an image, and
 * approximate diffuse colour.
 */

// Provided by three.js - [see](http://threejs.org/docs/#Reference/Renderers.WebGL/WebGLProgram)

// // Default vertex attributes provided by Geometry and BufferGeometry
// uniform vec3 cameraPosition;

uniform float time;

uniform vec2 resolution;

uniform float scale;

uniform float numBranches;

uniform vec2 frondAlignRange;
uniform float midFrequency;
uniform float frequencyCount;

uniform float frondGrowthLimit;

uniform float branchGrowthRate;
uniform float frondGrowthRate;
uniform float widthGrowthRate;

uniform float spreadBlur;
uniform float spreadSlope;

uniform float taperAmount;
uniform float taperAngle;

uniform float branchWidth;
uniform float frondWidth;
uniform float widthVariation;

uniform vec3 diffuse;
uniform float diffuseScatter;

uniform float airRefraction;
uniform float iceRefraction;

uniform float height;

uniform sampler2D deltas;

varying vec2 vUV;
varying vec3 vNormal;

// Libs.

/**
 * @requires constants
 * @requires functions
 * @requires trigonometry
 * @requires distance
 * @requires ray
 */

vec2 nucleus = 0.5*resolution*scale,
    branch = vec2(1.0, 0.0),
    branchNormal = perp(branch);

Ray2 branchRay = Ray2(nucleus, branch);


float mirrorAngle = pi/numBranches;

vec2 mirror = vec2(cos(mirrorAngle), sin(mirrorAngle)),
    toMirror = mirror-branch;


float growthLimit = length(toMirror);

vec2 midFrond = toMirror/growthLimit,
    maxFrond = normalize(mix(midFrond, branch, frondAlignRange[1])),
    minFrond = normalize(mix(midFrond, -branch, frondAlignRange[0]));

float refractionRatio = airRefraction/iceRefraction;


vec2 mirrorPos(vec2 position) {
    vec2 pos = position-branchRay.point;

    float r = length(pos),
        offset = atan(pos.y, pos.x)/mirrorAngle,
        mirrored = mirrorAngle*
            mix(fract(offset), 1.0-fract(offset), mod(floor(offset), 2.0));
    
    return branchRay.point+(vec2(cos(mirrored), sin(mirrored))*r);
}


Ray2 getFrond(float align, float t) {
    vec2 aligned = mix(mix(minFrond, midFrond, align/midFrequency),
            mix(midFrond, maxFrond, (align-midFrequency)/(1.0-midFrequency)),
            step(midFrequency, align));

    return Ray2(nucleus+(branch*t), normalize(aligned));
}


// May need a little work to give a linear scale and decent visibility across
// the spectrum.
float frondGrowth(vec2 direction, float size, float l, float t) {
    float limit = mix(1.0, l*(1.0-dot(direction, toMirror))*2.0, frondGrowthLimit);

    // return size*expStep(t, 1.0, -0.25)*limit;
    // return size*(1.0-expStep(t, 1.0, 1.2))*limit;
    // return size*cubicPulse(min(t, size), size, size)*limit;
    // return size*parabola(min(t*0.5, 0.7), 0.5*5.0*size)*limit;
    return size*parabola(min(t*0.5, 0.5), 0.5)*limit;
}

float pointGrowth(float growth, float size) {
    return size*pow(min(growth/size, 1.0), 0.5);
}


vec3 surfaceNormal(vec3 minNormal, vec3 maxNormal, float dist, float size) {
    return mix(minNormal, maxNormal, pow(step(dist, 1.0)*dist, size));
}

float taper(vec2 pos, Ray2 line, float l, float w, float t, float dotLimit) {
    return w*mix(1.0, max(0.0, angleDist(pos, line, l, w/t, dotLimit)),
            min(l/t/w, 1.0));
}


void main() {
    gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);

    // First, reflect into the segment bounded by the mirror or branch axes.
    vec2 uv = vUV*resolution*scale,
        pos = mirrorPos(uv),
        nearest;

    // Colour according to how close we are to the nucleus.
    float branchGrowth = time*branchGrowthRate,
        nucleusGrowth = pointGrowth(branchGrowth*widthGrowthRate, branchWidth),

        // Inside is below 1.0
        w = taper(pos, branchRay, branchGrowth, nucleusGrowth,
                taperAmount, taperAngle),
        dist2 = lineDist2(pos, branchRay, branchGrowth, w, nearest),

        // Inside is above 1.0
        spread = 1.0/dist2;

    vec3 fromNearest = vec3(pos-nearest, 0.0),
        // spreadNormal = vNormal;
        spreadNormal = fromNearest*spread;

    #ifdef crystal
        vec3 distNormal = surfaceNormal(vNormal, fromNearest, dist2, branchWidth);
    #endif

    for(float s = 0.0; s <= 1.0; s += deltasVStep) { if(s <= branchGrowth) {
        vec4 delta = texture2D(deltas,
                vec2(deltasUStep*0.5, s+(deltasVStep*0.5)));

        Ray2 frond = getFrond(delta[frondAlignInput], s);

        float deltaSize = delta[frondSizeInput],
            t = branchGrowth-s,

            lengthGrowth = frondGrowth(frond.direction, deltaSize,
                s, t*frondGrowthRate),

            widthGrowth = pointGrowth(t*widthGrowthRate,
                    mix(frondWidth, branchWidth,
                        delta[frondAlignInput]*widthVariation)),

            w = taper(pos, frond, lengthGrowth, widthGrowth,
                    taperAmount, taperAngle),

            frondDist2 = lineDist2(pos, frond, lengthGrowth, w, nearest),

            frondSpread = 1.0/frondDist2;

        vec3 fromNearest = vec3(pos-nearest, 0.0);

        spreadNormal += fromNearest*frondSpread;
        spread += frondSpread;

        #ifdef crystal
            // distNormal = ((min(1.0, dist2) > frondDist2)?
            //     fromNearest : distNormal);
            // distNormal = mix(distNormal, fromNearest,
            //         step(frondDist2, min(1.0, dist2)));
            distNormal = mix(distNormal,
                    surfaceNormal(vNormal, fromNearest, frondDist2, widthGrowth),
                    step(frondDist2, min(1.0, dist2)));

            dist2 = min(dist2, frondDist2);
        #endif

        // @todo: `break` and `continue` might crash certain browsers; check.
    } else { break; } }

    // Ignore anything outside the spread, and map it from an asymptote at
    // `dist2 == 0` to a parabola with 0 at `dist2 == 0`.
    // `spreadBlur` increases above 0 will reduce the range of the curve.
    // `spreadSlope` increases above 0 will flatten the top of curve.
    spread = spreadBlur/pow(max(spread-1.0, 0.0), spreadSlope);


    float closest;
    vec3 normal;

    #ifdef crystal
        closest = min(dist2, spread);
        normal = normalize(surfaceNormal(distNormal, spreadNormal, closest, 1.0));
    #else
        closest = spread;
        normal = normalize(surfaceNormal(vNormal, spreadNormal, closest, 1.0));
    #endif


    vec3 incident;

    #ifdef fromCamera
        incident = vec3(uv, 0.0)-cameraPosition;
    #else
        incident = -vNormal;
    #endif


    vec3 refracted = refract(incident, normal, refractionRatio);

    float slope = 1.0-dot(vNormal, normal),
        // h = height*(max(1.0-closest, 0.0)+slope);
        h = height*(1.0+max(1.0-closest, 0.0)+slope);
    
    vec2 sample = uv+(refracted.xy*h),
        image = mod(sample, vec2(0.5));
        //image = vec2(0.0);


    gl_FragColor.rgb += vec3(0.0, image)+
        (diffuse*pow(slope, refractionRatio)*length(incident)*diffuseScatter);
}
