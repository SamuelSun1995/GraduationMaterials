clc;
clear;
close all;

haze=imread('data/rc.png');
haze=double(haze)./255;
dehaze=run_cnn(haze);
dehaze_zyc=run_cnn_zyc(haze);
% subplot(m,n,p),m表示是图排成m行，n表示图排成n列，p=[a,b,c,..]是向量
figure;set(gcf,'Position',get(0,'ScreenSize'));
subplot(1,2,1);
imshow(haze),title('有雾图片');
subplot(1,2,2);
imshow(dehaze),title('去雾图片');
%subplot(1,3,3);
%imshow(dehaze_zyc),title('朱韵晨滤波');
