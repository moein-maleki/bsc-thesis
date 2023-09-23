clear; clc; close all;
%%
load woman
I = X;
imagesc(I)
colormap pink(255)

%% filter bank coeffecients - sym4
wv = "sym4";
filter_bank_dec = [-0.0322231006040427, -0.012603967262037833, ...
0.09921954357684722, 0.29785779560527736, ...
-0.8037387518059161, 0.49761866763201545, ...
0.02963552764599851, -0.07576571478927333; 
-0.07576571478927333, -0.02963552764599851, ...
0.49761866763201545, 0.8037387518059161, ...
0.29785779560527736, -0.09921954357684722, ...
-0.012603967262037833, 0.0322231006040427];


filter_bank_rec = [-0.07576571478927333, 0.02963552764599851, ...
0.49761866763201545, -0.8037387518059161, ...
0.29785779560527736, 0.09921954357684722, ...
-0.012603967262037833, -0.0322231006040427;
0.0322231006040427, -0.012603967262037833, ...
-0.09921954357684722, 0.29785779560527736, ...
0.8037387518059161, 0.49761866763201545, ...
-0.02963552764599851, -0.07576571478927333];

%%
decomposition_level = 2;
[rows, cols] = size(I);

% check row length
signal_length = rows;
modulus_value = mod(signal_length, 2^decomposition_level);
new_rows = rows;
if modulus_value ~= 0
    new_rows = (((signal_length-modulus_value) / 2^decomposition_level)  ... 
        + 1) * (2^decomposition_level); 
end
% check col length
signal_length = cols;
modulus_value = mod(signal_length, 2^decomposition_level);
new_cols = cols;
if modulus_value ~= 0
    new_cols = (((signal_length-modulus_value) / 2^decomposition_level)  ... 
        + 1) * (2^decomposition_level); 
end

I_ex = zeros(new_rows, new_cols);
I_ex(1:rows, 1:cols) = I;
I_ex = uint8(I_ex);
imagesc(I_ex)
colormap pink(255)

%%
[image_coeffs, image_bkeeping] = dwt_2d_analysis(I_ex, filter_bank_dec, decomposition_level);


%% plotting everything

figure
subplot(3,3,1)
imagesc(wcodemat(image_coeffs{decomposition_level+1},255))
colormap pink(255)

subplot(3,3,2)
imagesc(wcodemat(image_coeffs{2}{1},255))
colormap pink(255)

subplot(3,3,5)
imagesc(wcodemat(image_coeffs{2}{2},255))
colormap pink(255)

subplot(3,3,4)
imagesc(wcodemat(image_coeffs{2}{3},255))
colormap pink(255)

%
subplot(3,3,6)
imagesc(wcodemat(image_coeffs{1}{1},255))
colormap pink(255)

subplot(3,3,9)
imagesc(wcodemat(image_coeffs{1}{2},255))
colormap pink(255)

subplot(3,3,8)
imagesc(wcodemat(image_coeffs{1}{3},255))
colormap pink(255)

%%
[c,s]=wavedec2(X,2,'sym4');
[H1,V1,D1] = detcoef2('all',c,s,1);
[H2,V2,D2] = detcoef2('all',c,s,2);
A2 = appcoef2(c,s,'haar',2);

V1img = wcodemat(V1,255,'mat',1);
H1img = wcodemat(H1,255,'mat',1);
D1img = wcodemat(D1,255,'mat',1);
V2img = wcodemat(V2,255,'mat',1);
H2img = wcodemat(H2,255,'mat',1);
D2img = wcodemat(D2,255,'mat',1);
A2img = wcodemat(A2,255,'mat',1);

figure
subplot(3,3,1)
imagesc(A2img)
colormap pink(255)
title('Approximation Coef. of Level 2')

subplot(3,3,2)
imagesc(V2img)
title('Vertical Detail Coef. of Level 1')

subplot(3,3,5)
imagesc(D2img)
title('Diagonal Detail Coef. of Level 1')

subplot(3,3,4)
imagesc(H2img)
title('Horizontal Detail Coef. of Level 1')

%
subplot(3,3,6)
imagesc(V1img)
title('Vertical Detail Coef. of Level 1')

subplot(3,3,9)
imagesc(D1img)
title('Diagonal Detail Coef. of Level 1')

subplot(3,3,8)
imagesc(H1img)
title('Horizental  Detail Coef. of Level 1')






