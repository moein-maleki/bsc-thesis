clc; clear; close all;
%%

TOTAL_INPUTS = 256;
x = (1:1:1000);
x=x(1:TOTAL_INPUTS);
qin = quantizer([32, 0]);
%%
write_bin_content("../test_inputs.txt", x, qin);
%%
formatSpec = '%c\n';  
qout = qin;

outputs_fd          = fopen("../a_outputs.txt",  'r');
a_outputs_content	= fscanf(outputs_fd, formatSpec);
fclose(outputs_fd);
a_outputs           = read_bin_content(a_outputs_content, qout, 265, 32);
bkeeping            = [129, 66, 34, 18, 18];
%%
d1 = a_outputs(1:129);
d2 = a_outputs(130:130+65);
d3 = a_outputs(196:196+33);
d4 = a_outputs(196+34:196+34+17);
a = a_outputs(196+34+18:196+34+18+17);


subplot(6, 1, 1)
plot(x)
xlim([1 TOTAL_INPUTS])

subplot(6, 1, 2)
plot(d1)
xlim([1 129])

subplot(6, 1, 3)
plot(d2)
xlim([1 66])

subplot(6, 1, 4)
plot(d3)
xlim([1 34])

subplot(6, 1, 5)
plot(d4)
xlim([1 18])

subplot(6, 1, 6)
plot(a)
xlim([1 18])