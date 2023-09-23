clear; clc;
%% input signals
fs = 1e3;
t = 0:1/fs:2-1/fs;
y = chirp(t,0,1,250);
% plot(t, y)

%% dwt filterbanks
wv = "db2";
len = numel(y);
for dec_level = 1:3
    fb = dwtfilterbank('SignalLength', len, 'Wavelet',wv, ...
        'Level', dec_level, 'SamplingFrequency', fs);
    [phi, t] = scalingfunctions(fb);
end
% plot(t, phi')
grid on

%% dwt decompistion
[coeffs, bkeeping] = wavedec(y, 3, wv);
approx = appcoef(coeffs, bkeeping, 'db2');
[cd1,cd2,cd3] = detcoef(coeffs, bkeeping, [1 2 3]);

%% dwt decompistion
[coeffs, bkeeping] = wavedec(y, 1, wv);
approx = appcoef(coeffs, bkeeping, 'db2');
cd1 = detcoef(coeffs, bkeeping, 1);

%% plotting wavelet coefficients
subplot(4,1,1)
plot(approx)
xlim([1 numel(approx)]);
title('Approximation Coefficients')
subplot(4,1,2)
plot(cd1)
xlim([1 numel(cd1)]);
title('Level 1 Detail Coefficients')
subplot(4,1,3)
plot(cd2)
xlim([1 numel(cd2)]);
title('Level 2 Detail Coefficients')
subplot(4,1,4)
plot(cd3)
xlim([1 numel(cd3)]);
title('Level 3 Detail Coefficients')

%% reconstruction of the signal
t = 0:1/fs:2-1/fs;
y_synth = waverec(coeffs, bkeeping, wv);

%% plotting the synthesized signal
% diff = y - y_synth;
% subplot(3,1,1)
% plot(t, y)
% title('Original Signal')
% subplot(3,1,2)
% plot(t, y)
% title('Reconstructed Signal')
% subplot(3,1,3)
% plot(t, diff)
% title('Differences')

%% error
err = norm(y-y_synth);
