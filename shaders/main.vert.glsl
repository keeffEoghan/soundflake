/**
 * Just render flat to the viewport.
 */

// Provided by three.js - [see](http://threejs.org/docs/#Reference/Renderers.WebGL/WebGLProgram)

// // Default vertex attributes provided by Geometry and BufferGeometry
// attribute matrix4x4 projectionMatrix;
// attribute matrix4x4 modelViewMatrix;
// attribute vec3 position;
// attribute vec3 normal;
// attribute vec2 uv;

varying vec2 vUV;
varying vec3 vNormal;

void main() {
    gl_Position = projectionMatrix*modelViewMatrix*vec4(position, 1.0);
    vUV = uv;
    vNormal = normal;
}
