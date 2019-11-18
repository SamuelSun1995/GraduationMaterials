%clear workspace
clear;
clc;

%load test_picture （加载测试照片）
[fName pName]=uigetfile({'*.*'},'Open');

if fName
        original_im=imread([pName fName]); %读入图片
    end
    %formatting im to float  （格式化图片）

    original_im = double(original_im);
    % separate different channels - RGB（分开不同的通道 -  RGB）
R_channel = original_im(:, :, 1);
G_channel = original_im(:, :, 2);
B_channel = original_im(:, :, 3);

%create original_dark_channel image with same size（创建大小相同的original_dark_channel图像）
[row, column] = size(R_channel);  % row表示行数，column表示列数
dark_channel_image = zeros(row,column);  %zeros生成一个零矩阵

%% 求出RGB通道中像素点最低的通道
%extract the minimum value of each point in RGB for dark_channel_image （为dark_channel_image提取RGB中每个点的最小值）
for i=1:row
    for j=1:column
        local_pixels =[R_channel(i,j), G_channel(i,j), B_channel(i,j)]; 
        dark_channel_image(i,j) = min(local_pixels );
    end
end

%image erode, minimum filtering（图像腐蚀，最小过滤）
kernel = ones(30);  %ones(N) - 生成N行N列且所有元素均为1的矩阵 （kernel 核心）
final_im = imerode(dark_channel_image, kernel); %dark_channel_image暗通道图像（待处理的图像），kernel：30*30的全1矩阵（结构元素）
%最小值滤波
%final_im = ordfilt2(dark_channel_image,1,kernel);

%腐蚀的原理：https://blog.csdn.net/yarina/article/details/51354278
%二值图像前景物体为1，背景为0.假设原图像中有一个前景物体，那么我们用一个结构元素去腐蚀原图的过程是这样的：遍历原图像的每一个像素，
%然后用结构元素的中心点对准当前正在遍历的这个像素，然后取当前结构元素所覆盖下的原图对应区域内的所有像素的最小值，用这个最小值替换当前像素值。
%由于二值图像最小值就是0，所以就是用0替换，即变成了黑色背景。从而也可以看出，如果当前结构元素覆盖下，全部都是背景，那么就不会对原图做出改动，
%因为都是0.如果全部都是前景像素，也不会对原图做出改动，因为都是1.只有结构元素位于前景物体边缘的时候，它覆盖的区域内才会出现0和1两种不同的像
%素值，这个时候把当前像素替换成0就有变化了。因此腐蚀看起来的效果就是让前景物体缩小了一圈一样。对于前景物体中一些细小的连接处，如果结构元素大
%小相等，这些连接处就会被断开。


%transform dark_channel_imaege into Picture Format（将dark_channel_imaege转换为图片格式）
final_im = uint8(final_im);    %final_im是暗通道图像
figure;set(gcf,'Position',get(0,'ScreenSize'));
%subplot(2,2,1), imshow(final_im);
%title("Dark Channel Prior");
%% 以上是求图像的暗通道的图像

%definne the size of filter_window（定义滤波器窗口的大小）
wid_x = 2;
wid_y = 2;

%augment image by pixels(value=128)（按像素增加图像）
augmented_im = ones(row+2*wid_x, column+2*wid_y, 3) * 128;
augmented_im(wid_x+1:row+wid_x, wid_y+1:column+wid_y, :) = original_im;

%find the value of Atmospheric light, which is the mean of top 0.1% value（找到大气光的值，这是最高0.1％值的平均值）
%in dark_channel_prior（求A）
%% 大气光A为暗通道中最亮的0.1%
%v_ac = reshape(dark_channel_image,1,column*row);
v_ac = reshape( double(final_im),1,column*row);
v_ac = sort(v_ac, 'descend');  %descend降序排，dim升序排
Ac = mean(v_ac(1:uint8(0.001*column*row)));
%%
%define and calculate minimum_matrix （定义并计算最小矩阵）
minimum = zeros(row+2*wid_x, column+2*wid_y);
for i= wid_x+1 : row+wid_x
    for j=wid_y+1: column+wid_y
        %extract local_window（提取local_window）
        local_window = augmented_im(i-wid_x:i+wid_x, j-wid_y:j+wid_y, :);
        %separate RGB channels（单独的RGB通道）
        local_r = local_window(:, :, 1);
        local_g = local_window(:, :, 2);
        local_b = local_window(:, :, 3);
        
        %normalize this current pixel in 3 channels（将此当前像素标准化为3个通道）
        channel_values = [ R_channel(i-wid_x,j-wid_y) / Ac, G_channel(i-wid_x,j-wid_y) / Ac, B_channel(i-wid_x,j-wid_y) / Ac ];
        %find the min values in 3 channels（找到3个通道中的最小值）
        minimum(i,j) = min(channel_values);
    end
end

%recover the augmented marix to previous size（将增强矩阵恢复到先前的大小）
%original_minimum = ones(row,column);
original_minimum = minimum(wid_x+1:wid_x+row, wid_y+1:wid_y+column);

%assign the local minimum for each point(Image Erode) （为每个点指定局部最小值（Image Erode））
kernel_erode = ones(2*wid_x+1,2*wid_y+1);
min_minimum = imerode(original_minimum, kernel_erode);

%define w as a parameter for adjustment （将w定义为调整参数）
w=0.95;
%define and calculate transmittance matrix （定义和计算透射率矩阵）
pre_t = ones(row,column);
true_t = pre_t - w*min_minimum;  %恢复矩阵
%滤波
r = 50;
eps = 10^(-6);
%true_t = weightedguidedfilter(dark_channel_image,true_t,r,eps);
true_t = guidedfilter(dark_channel_image,true_t,r,eps);
true_w = guidedfilter_w(dark_channel_image,true_t,r,eps);
%subplot(2,2,2), imshow(uint8(true_t*255));  %true_t透射图
%subplot(2,2,3), imshow(uint8(true_t*255));  %true_t透射图
%title("Transmittance map");         

%set up a threshold for light transmittance（设置透光率阈值）
K=55;
t0=0.1;
p=0.5;
for i=1:row
    for j=1:column
       true_t_1(i,j) = max(t0, true_t(i,j)); 
       true_t_2(i,j) = min((max(K /abs(original_im(i,j) - Ac),1))* max(t0, true_t(i,j)),1);
       true_t_3(i,j) = min((max(1+log10(K /abs(original_im(i,j) - Ac)),1))* max(t0, true_t(i,j)),1);
       true_t_4(i,j) = min((max((1+log10(K /abs(original_im(i,j) - Ac)))^p,1))* max(t0, true_w(i,j)),1);
       true_t_5(i,j) = min((max((1+log10(K /abs(original_im(i,j) - Ac)))^p,1))* max(t0, true_t(i,j)),1);
    end
end

%recover the final image by haze function（通过雾霾功能恢复最终图像）
final_image_1 = (original_im - Ac) ./ true_t_1 +Ac;
final_image_1 = uint8(final_image_1);

final_image_2 = (original_im - Ac) ./ true_t_2 +Ac;
final_image_2 = uint8(final_image_2);

final_image_3 = (original_im - Ac) ./ true_t_3 +Ac;
final_image_3 = uint8(final_image_3);

final_image_4 = (original_im - Ac) ./ true_t_4 +Ac;
final_image_4 = uint8(final_image_4);

final_image_5 = (original_im - Ac) ./ true_t_5 +Ac;
final_image_5 = uint8(final_image_5);

%show the result（显示结果）
%figure;set(gcf,'Position',get(0,'ScreenSize'));
%subplot(2,2,3), imshow(uint8(original_im));
%title("Original image");

subplot(1,4,2),imshow(final_image_1);
title("After processing");
title("原方法");

%subplot(1,4,3),imshow(final_image_2);
%title("容差机制");

subplot(1,4,1),imshow(uint8(original_im));
title("原图");

subplot(1,4,3),imshow(final_image_5);
title("导向滤波")

subplot(1,4,4),imshow(final_image_4);
title("加权导向滤波")
%title("我的改进(p="+p+")");