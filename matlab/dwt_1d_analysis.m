function [dwt_coeffs, bookkeeping] = dwt_1d_analysis( ...
    input_signal, ...
    filter_bank_dec, ...
    decomposition_level, ...
    downsample)

    signal_length = numel(input_signal);
    approx_coeffs = input_signal;
    dwt_coeffs= zeros(decomposition_level+1, floor((signal_length+length(filter_bank_dec)-1)/2));
    bookkeeping = zeros(1, decomposition_level+2);

    for dec_level = 1:decomposition_level
        
        % perform dwt analysis. result is [detail, approx] coefficients
        detail_coeffs = apply_filter(approx_coeffs, filter_bank_dec(1,:));
        approx_coeffs = apply_filter(approx_coeffs, filter_bank_dec(2,:));
        
        % downsample the resulting coefficients by a factor of 2
        detail_coeffs = down_sample(detail_coeffs);
        approx_coeffs = down_sample(approx_coeffs);
        
        coeffs_length = length(approx_coeffs);
        bookkeeping(dec_level) = coeffs_length;

        % store the results in an array
        dwt_coeffs(dec_level, 1:coeffs_length) = detail_coeffs(1:coeffs_length);
    end

    % store the last level's approx coefficients
    dwt_coeffs(decomposition_level+1, 1:coeffs_length) = approx_coeffs(1:coeffs_length);
    bookkeeping(decomposition_level+1) = coeffs_length;
    bookkeeping(end) = signal_length;
end

