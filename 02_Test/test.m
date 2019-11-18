clc;
clear;
close all;

%% 求一幅图像的暗通道图像，窗口大小为15*15
imageRGB = imread('data/mountain.jpg');
imageRGB = double(imageRGB);
imageRGB = imageRGB./255;
dark = darkChannel(imageRGB);

%% 选取暗通道中最亮的0.1%像素，从而取得大气光
[m, n, ~] = size(imageRGB);
imsize = m*n;
numpx = floor(imsize/1000);
JDarkVec = reshape(dark,imsize,1);
ImVec = reshape(imageRGB,imsize,3);

[JDarkVec, indices] = sort(JDarkVec);
indices = indices(imsize-numpx+1:end);
atmSum = zeros(1,3);
for ind = 1:numpx
    atmSum = atmSum + ImVec(indices(ind),:);
end
atmospheric = atmSum / numpx;

%% 求解透射率，并通过omega参数来选择保留一定程度雾霾，以免损坏真实感
omega = 0.95;
im = zeros(size(imageRGB));

for ind = 1:3
    im(:,:,ind) = imageRGB(:,:,ind)./atmospheric(ind);
end

dark_2 = darkChannel(im);
t = 1 - omega*dark_2;

%% 通过导向滤波来获得更为精细的透射图 
r = 60;
eps = 10^-6;
refined_t = weightedguidedfilter(imageRGB,t,r,eps);
%refined_t = guidedfilter_color(imageRGB,t,r,eps);

refinedRadiance = getRadiance(atmospheric,imageRGB,refined_t);