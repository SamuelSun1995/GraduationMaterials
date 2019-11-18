function [ dehaze ] = run_cnn( im )
%RUN_CNN Summary of this function goes here
%   Detailed explanation goes here
%https://blog.csdn.net/u012556077/article/details/53364438（此代码的解释出处）
%https://blog.csdn.net/ametor/article/details/51274274
%https://blog.csdn.net/zonglingkui1591/article/details/79776555
r0 = 50;
eps = 10^-3; 
gray_I = rgb2gray(im);

load dehaze
haze=im-0.5;

%% Feature Extraction F1(特征提取F1)
f1=convolution(haze, weights_conv1, biases_conv1);
F1=[];
%语法是 A = reshape（A，m，n）； 或者 A = reshape（A，[m,n]）; 都是将A 的行列排列成m行n列。另外 reshape是 按照列取数据的，
%r=size(A,1)该语句返回的时矩阵A的行数， c=size(A,2) 该语句返回的时矩阵A的列数。
f1temp=reshape(f1,size(f1,1)*size(f1,2),size(f1,3));
%for其中1:2:10表示迭代从1开始，步长为2，最大不超过10，即代表行向量1 3 5 7 9。
for step=1:4    %从1开始步长为4     %x(i,j,k)的含义是第k层矩阵的第i行第j列元素;  x(:,:,1)则表示第1层矩阵。
    maxtemp=max(f1temp(:,(step*4-3):step*4),[],2); %求步长中的t最大值  
    F1=[F1,maxtemp]; %#ok<AGROW>    %把最大值放在矩阵中
end
F1=reshape(F1,size(f1,1),size(f1,2),size(F1,2));

%% Multi-scale Mapping F2 (多尺度映射F2)
F2=zeros(size(F1,1),size(F1,2),48);
F2(:,:,1:16)=convolution(F1, weights_conv3x3, biases_conv3x3);
F2(:,:,17:32)=convolution(F1, weights_conv5x5, biases_conv5x5);
F2(:,:,33:48)=convolution(F1, weights_conv7x7, biases_conv7x7);

%% Local Extremum F3(最后当地F3)
F3=convMax(single(F2), 3);

%% Non-linear Regression F4(非线性回归F4)
F4=min(max(convolution(F3, weights_ip, biases_ip),0),1);

%% Atmospheric light (大气光)
sortdata = sort(F4(:), 'ascend');
idx = round(0.01 * length(sortdata));   %最亮的0.01
val = sortdata(idx); 
id_set = find(F4 <= val);
BrightPxls = gray_I(id_set);
iBright = BrightPxls >= max(BrightPxls);
id = id_set(iBright);
Itemp=reshape(im,size(im,1)*size(im,2),size(im,3));
A = mean(Itemp(id, :),1);
A=reshape(A,1,1,3);

%进行滤波处理
%指导图像：gray_I（应该是灰度/单通道图像）
%过滤输入图像：F4（应为灰度/单通道图像）
%局部窗口半径：r0
%正则化参数：eps
F4 = guidedfilter(gray_I, F4, r0, eps);
%F4 = weightedguidedfilter(gray_I, F4, r0, eps);   

J=bsxfun(@minus,im,A);  %减法
J=bsxfun(@rdivide,J,F4); %点除
J=bsxfun(@plus,J,A); %加法                        
%A=[1 2 3]
%B=[4; 5 ;6]
%bsxfun(@plus,A,B)
%A =
%     1     2     3
%B =
%     4
%     5
%     6
%ans =
%     5     6     7
%     6     7     8
%     7     8     9
dehaze=J;
end

