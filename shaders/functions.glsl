/**
 * Functions that produce useful graphs.
 */

// From Iñigo Quilez - http://www.iquilezles.org/www/articles/functions/functions.htm

float impulse(float x, float k) {
    float h = k*x;

    return h*exp(1.0-h);
}

float parabola(float x, float k) {
    return pow(4.0*x*(1.0-x), k);
}

float cubicPulse(float x, float c, float w) {
    x = abs(x-c);

    if(x > w) {
    	return 0.0;
    }
    else {
    	x /= w;

    	return 1.0-(x*x*(3.0-(2.0*x)));
    }
}

float expStep(float x, float k, float n) {
    return exp(-k*pow(x, n));
}
