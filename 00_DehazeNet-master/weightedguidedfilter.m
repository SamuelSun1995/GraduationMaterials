function q = weightedguidedfilter(g, p, r, eps)

[h,w] = size(g);
N = boxfilter(ones(h,w),r);

wxy = guidedfilter(g, g.*p, r, eps);
wxx = guidedfilter(g, g.*g, r, eps);
wy = guidedfilter(g, p, r, eps);
wx = guidedfilter(g, g, r, eps);

a = abs(wxy - wy.*wx) ./(abs(wxx - wx.*wx) + eps);
b = wy - a.*wx;

mean_a = guidedfilter(g, a, r, eps);
mean_b = guidedfilter(g, b, r, eps);

q = mean_a .* g + mean_b;
end