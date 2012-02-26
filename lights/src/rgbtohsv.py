def RGBtoHSV(r, g, b):
    mmin = min( r, g, b );
    mmax = max( r, g, b );
    v = mmax;                # v
    delta = mmax - mmin;
    if mmax != 0:
        s = delta / mmax;        # s
    else:
        # r = g = b = 0        // s = 0, v is undefined
        s = 0;
        h = -1;
        return (h,s,v)
    if r == mmax:
        h = ( g - b ) / delta       # between yellow & magenta
    elif g == mmax:
        h = 2 + ( b - r ) / delta   # between cyan & yellow
    else:
        h = 4 + ( r - g ) / delta   # between magenta & cyan
    h *= 60             # degrees
    if h < 0 :
        h += 360
    return (h,s,v)


if __name__ == "__main__":
	print RGBtoHSV(0,40,0)
