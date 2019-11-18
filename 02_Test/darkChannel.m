function [dark] = darkChannel(imRGB)
r=imRGB(:,:,1);
g=imRGB(:,:,2);
b=imRGB(:,:,3);

[m n] = size(r);
a = zeros(m,n);
for i = 1:m
    for j = 1: n
        a(i,j) = min(r(i,j),g(i,j));
        a(i,j) = min(a(i,j),b(i,j));
    end
end
d = ones(15,15);
fun = @(block_struct)min(min(block_struct.data))*d;
dark = blockproc(a,[15 15], fun);

dark = dark(1:m, 1:n);
