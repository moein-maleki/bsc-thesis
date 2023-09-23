clear; clc; close all;
%% input signal
load mit200
figure
plot(tm,ecgsig)
hold on
plot(tm(ann),ecgsig(ann),'ro')
xlabel('Seconds')
ylabel('Amplitude')
title('Subject - MIT-BIH 200')

%%
TOTAL_INPUTS = 2048;

decomposition_level = 4;
wavelet_family = "sym16";
downsampling = 1;

y = (ecgsig');
y = y(1:TOTAL_INPUTS);
y = (y / max(abs(max(y)), abs(min(y)))) * 0.1;

fs = 360; %hz
disp(["Input time length: ", TOTAL_INPUTS/fs])

%%
FIR_INPUT_WIDTH         = 32;
FIR_INPUT_FRACTIONS     = 31;
FIR_COEFF_WIDTH         = 32;
FIR_COEFF_FRACTIONS     = 31;
FIR_OUTPUT_WIDTH        = 32;
FIR_OUTPUT_FRACTIONS    = 31;

qout                = quantizer([FIR_OUTPUT_WIDTH,	FIR_OUTPUT_FRACTIONS]);
qin                 = quantizer([FIR_INPUT_WIDTH,   FIR_INPUT_FRACTIONS]);
qcoeffs             = quantizer([FIR_COEFF_WIDTH,   FIR_COEFF_FRACTIONS]);

%%
a_outputs_path      = '../a_outputs.txt';
aftab_outputs_path 	= '../aftab_outputs.txt';

a_hid_outputs_path 	= '../filter_outputs_HID.txt';
a_lod_outputs_path 	= '../filter_outputs_LOD.txt';

inputs_path         = '../filter_inputs.txt';
coeffs_HID_path     = '../filter_coeffs_HID.txt';
coeffs_LOD_path     = '../filter_coeffs_LOD.txt';

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

%% filter bank coeffecients - db2
[LoD,HiD,LoR,HiR] = wfilters(wavelet_family);
filter_bank_dec = [HiD; LoD];
filter_bank_rec = [HiR; LoR];

FIR_SIZE = numel(HiD);

%% writing inputs and filter ceofficients to file
write_bin_content(coeffs_HID_path, HiD, qcoeffs);
write_bin_content(coeffs_LOD_path, LoD, qcoeffs);
write_bin_content(inputs_path, y_ex, qin);

write_hex_content("../hex_inputs.txt", y_ex, qin);
write_hex_content("../hex_coeffs_hid.txt", HiD, qcoeffs);
write_hex_content("../hex_coeffs_lod.txt", LoD, qcoeffs);

coeffs_HID_fd   	= fopen(coeffs_HID_path,   'r');
coeffs_LOD_fd       = fopen(coeffs_LOD_path,   'r');
inputs_fd           = fopen(inputs_path,   'r');

formatSpec = '%c\n';  
fir_inputs              = fscanf(inputs_fd, formatSpec);
fir_coeffs_HID          = fscanf(coeffs_HID_fd, formatSpec);
fir_coeffs_LOD          = fscanf(coeffs_LOD_fd, formatSpec);

fclose(inputs_fd);
fclose(coeffs_HID_fd);
fclose(coeffs_LOD_fd);

hid_coeffs  = read_bin_content(fir_coeffs_HID, qcoeffs, FIR_SIZE, FIR_COEFF_WIDTH);
lod_coeffs  = read_bin_content(fir_coeffs_LOD, qcoeffs, FIR_SIZE, FIR_COEFF_WIDTH);
inputs      = read_bin_content(fir_inputs, qin, TOTAL_INPUTS, FIR_INPUT_WIDTH);

%% perform my 1-d dwt
[dwt_coeffs, bookkeeping] = dwt_1d_analysis(inputs, ...
    filter_bank_dec, decomposition_level, downsampling);
myCode_details = extract_details(dwt_coeffs, bookkeeping);
myCode_approx = extract_approx(dwt_coeffs, bookkeeping);

%% dwt using matlabs functions
dwtmode('zpd');
[wavedec_coeffs, bkeeping] = wavedec(inputs, decomposition_level, wavelet_family);
wavedec_approx = appcoef(wavedec_coeffs, bkeeping, wavelet_family);
aux_array = zeros(1, decomposition_level);
for i = 1:decomposition_level
    aux_array(i) = i;
end
wavedec_details = cell(1, decomposition_level);
temp = detcoef(wavedec_coeffs, bkeeping, aux_array);

if decomposition_level == 1
    wavedec_details{1} = temp;
else
    wavedec_details = temp;
end

%% read accelerator results
outputs_fd          = fopen(a_outputs_path,  'r');
% outputs_fd          = fopen(aftab_outputs_path,  'r');
a_outputs_content	= fscanf(outputs_fd, formatSpec);
fclose(outputs_fd);
%% read accelerator results
a_bkeeping=zeros(1, decomposition_level + 1);
cur_inputs_len = TOTAL_INPUTS;
filter_size = length(HiD);
for i=1:decomposition_level
    cur_output_len = floor((cur_inputs_len + filter_size -1)/2);
    a_bkeeping(i) = cur_output_len;
    cur_inputs_len = cur_output_len;
end
a_bkeeping(i+1) = cur_output_len;
a_outputs           = read_bin_content(a_outputs_content, qout, sum(a_bkeeping), FIR_OUTPUT_WIDTH);

%% read accelerator results
a_details = cell(1, decomposition_level);
a_bkeeping = [0 a_bkeeping];
for i = 1:decomposition_level
    start_idx = sum(a_bkeeping(1:i)) + 1;
    end_idx = sum(a_bkeeping(1:i+1));
    a_details{i} = a_outputs(start_idx:end_idx);
end
a_approx = a_outputs(sum(a_bkeeping(1:i+1))+1:end);
a_bkeeping = a_bkeeping(2:end);
%% read accelerator results
% hid_outputs_fd      = fopen(a_hid_outputs_path,  'r');
% lod_outputs_fd      = fopen(a_lod_outputs_path,  'r');
% 
% achieved_outputs_hid    = fscanf(hid_outputs_fd, formatSpec);
% achieved_outputs_lod    = fscanf(lod_outputs_fd, formatSpec);
% 
% fclose(hid_outputs_fd);
% fclose(lod_outputs_fd);
% 
% a_outputs_hid = read_bin_content(achieved_outputs_hid, qout, TOTAL_OUTPUTS, FIR_OUTPUT_WIDTH);
% a_outputs_lod = read_bin_content(achieved_outputs_lod, qout, TOTAL_OUTPUTS, FIR_OUTPUT_WIDTH);

%% plot and compare results
figure
subplot(4, decomposition_level+1,1);

for i = 1:decomposition_level
    % inputs plot
    subplot(4, decomposition_level+1,i);
    plot(inputs)
    title('Inputs')
    xlim([1 TOTAL_INPUTS])

    % matlab's details
    subplot(4, decomposition_level+1, decomposition_level+1+i);
    plot(wavedec_details{i})
    title(['Matlab''s D', num2str(i)])
    xlim([1 a_bkeeping(i)])
    
    % my code's details
    subplot(4, decomposition_level+1, 2*(decomposition_level+1)+i);
    plot(myCode_details{i})
    title(['My Code''s D', num2str(i)])
    xlim([1 a_bkeeping(i)])

    % accelerator details
    subplot(4, decomposition_level+1, 3*(decomposition_level+1)+i);
    plot(a_details{i})
    title(['Accelerator''s D', num2str(i)])
    xlim([1 a_bkeeping(i)])
end

% inputs plot
subplot(4, decomposition_level+1, decomposition_level+1);
plot(inputs)
title('Inputs')
xlim([1 TOTAL_INPUTS])

% matlab's details
subplot(4, decomposition_level+1, 2*(decomposition_level+1));
plot(wavedec_approx)
title('Matlab''s Approx')
xlim([1 a_bkeeping(end)])

% my code's approx
subplot(4, decomposition_level+1, 3*(decomposition_level+1));
plot(myCode_approx)
title('My Code''s Approx')
xlim([1 a_bkeeping(end)])

% accelerator approx
subplot(4, decomposition_level+1, 4*(decomposition_level+1));
plot(a_approx)
title('Accelerator''s Approx')
xlim([1 a_bkeeping(end)])

%% displaying errors

a_err = zeros(1, decomposition_level+1);
myCode_err = zeros(1, decomposition_level+1);

for i = 1:decomposition_level
    a_err(i) = sqrt(mean((a_details{i} - wavedec_details{i}).^2));
    myCode_err(i) = sqrt(mean((myCode_details{i} - wavedec_details{i}).^2)); 
end
a_err(i+1) = sqrt(mean((a_approx - wavedec_approx).^2));
myCode_err(i+1) = sqrt(mean((myCode_approx - wavedec_approx).^2));

disp("ERR: my code and matlab")
disp(myCode_err)

disp("ERR: my accelerator and matlab")
disp(a_err)

disp("MEAN ERR: my accelerator and matlab")
disp(mean(a_err))
