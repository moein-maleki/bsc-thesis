clear; clc; close all;
%% input signal
load mit200;
% figure
% plot(tm,ecgsig)
% hold on
% plot(tm(ann),ecgsig(ann),'ro')
% xlabel('Seconds')
% ylabel('Amplitude')
% title('Subject - MIT-BIH 200')

%%
fs = 360;
finish_time = 2;
y = (ecgsig');
y = y(1:finish_time*fs);

%% wavelet settings
decomposition_level = 2;
downsample = 1;
wavelet_family = "db2";

%% signal extension - zero padding
signal_length = numel(y);
modulus_value = mod(signal_length, 2^decomposition_level);
if modulus_value ~= 0
    new_length = (((signal_length-modulus_value) / 2^decomposition_level)  ... 
        + 1) * (2^decomposition_level); 
    y_ex = zeros(1, new_length);
    y_ex(1:signal_length) = y;
    signal_length = new_length;
else
    y_ex = y;
end

%% filter bank coeffecients
[LoD,HiD,LoR,HiR] = wfilters(wavelet_family);
filter_bank_dec = [HiD; LoD];
filter_bank_rec = [HiR; LoR];

%% applying my manual dwt analysis
[us_dwt_coeffs, us_bkeeping] = dwt_1d_analysis( ...
    y_ex, ...
    filter_bank_dec, ...
    decomposition_level, ...
    downsample);

us_details = extract_details(us_dwt_coeffs, us_bkeeping);
us_approx = extract_approx(us_dwt_coeffs, us_bkeeping);

%% use this for when downsample == 0
if downsample == 0
    [swa, swd] = swt(y_ex, decomposition_level, LoD, HiD);
    subplot(3,2,1);
    plot(y_ex);
    title('input')
    subplot(3,2,3);
    plot(swd);
    title('details')
    subplot(3,2,5);
    plot(swa);
    title('approx')

    subplot(3,2,2);
    plot(y_ex);
    title('input')
    subplot(3,2,4);
    plot(us_details{1});
    title('details')
    subplot(3,2,6);
    plot(us_approx);
    title('approx')
end

%% applying matlab's synthesis function on my coeffs
s_bkeeping = convert_coeff_bkeep(us_bkeeping);
s_dwt_coeffs = convert_coeff_ds(us_dwt_coeffs, us_bkeeping);

y_synth = waverec(s_dwt_coeffs,s_bkeeping,filter_bank_rec(2,:),filter_bank_rec(1,:));
disp('error of matlab''s synthesis function - performed on my coeffs')
hyb_err = norm(y_ex-y_synth)

%% dwt using matlabs functions
[wavedec_coeffs, bkeeping] = wavedec(y, decomposition_level, wavelet_family);
wavedec_approx = appcoef(wavedec_coeffs, bkeeping, wavelet_family);
aux_array = zeros(1, decomposition_level);
for i = 1:decomposition_level
    aux_array(i) = i;
end
wavedec_details = detcoef(wavedec_coeffs, bkeeping, aux_array);

%% plotting my and matlab's coefficients
figure
% plot detail coefficients
for dec_level = 1:decomposition_level
    subplot(3, decomposition_level+1, dec_level);
    plot(wavedec_details{dec_level})
    title(['Matlab''s Level ',num2str(dec_level),' Detail Coefficients'])
    max_ = max(wavedec_details{dec_level});
    ylim([-max_ max_])
    
    subplot(3, decomposition_level+1, dec_level+decomposition_level+1);
    plot(us_details{dec_level}(1:length(wavedec_details{dec_level})))
    title(['My Level ',num2str(dec_level),' Detail Coefficients'])
    ylim([-max_ max_])
    
    subplot(3, decomposition_level+1, dec_level+2*decomposition_level+2);
    plot(wavedec_details{dec_level} - ...
        us_details{dec_level}(1:length(wavedec_details{dec_level})))
    title('Difference')
    ylim([-0.5 0.5])
end

% plot approximation coefficients
subplot(3, decomposition_level+1, decomposition_level+1);
plot(wavedec_approx)
title('Matlab''s Approximation Coefficients')
max_ = max(wavedec_approx);
ylim([-max_ max_])

subplot(3, decomposition_level+1, 2*(decomposition_level+1));
plot(us_approx(1:length(wavedec_approx)))
title('My Approximation Coefficients')
ylim([-max_ max_])

subplot(3, decomposition_level+1, 3*(decomposition_level+1));
plot(wavedec_approx - us_approx(1:length(wavedec_approx)))
title('Difference')
ylim([-0.5 0.5])

%% errors between my and matlab's coefficients
coefficient_errors = zeros(1, decomposition_level+1);
for dec_level = 1:decomposition_level
    coefficient_errors = norm(wavedec_details{dec_level} - ...
        us_details{dec_level}(1:length(wavedec_details{dec_level})));
end
coefficient_errors(decomposition_level+1) = ...
    norm(wavedec_approx - us_approx(1:length(wavedec_approx)));

%% applying my manual synthesis
us_synthezised = dwt_synthesis(us_dwt_coeffs, us_bkeeping, filter_bank_rec, decomposition_level);

disp('error of my synthesis function - performed on my coeffs')
my_err = norm(y_ex-us_synthezised)

%% plotting the synthesized signal
diff = y_ex - us_synthezised;

figure
subplot(3,1,1)
plot(y_ex)
xlim([1 length(y_ex)])
title('Original Signal')

subplot(3,1,2)
plot(us_synthezised)
xlim([1 length(us_synthezised)])
title('Reconstructed Signal')

subplot(3,1,3)
plot(diff)
title('Differences')
xlim([1 length(diff)])

%% dwt reconstruction using matalbs functions
y_synth = waverec(wavedec_coeffs, bkeeping, wavelet_family);
disp('error of matlab''s synthesis function - performed on matlab''s coeffs')
matlab_err = norm(y-y_synth)

