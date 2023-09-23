function synthesized_signal = dwt_synthesis(us_dwt_coeffs, us_bkeeping, filter_bank_rec, decomposition_level)
    
    % extract coefficients from my data structures
    us_details = extract_details(us_dwt_coeffs, us_bkeeping);
    us_approx = extract_approx(us_dwt_coeffs, us_bkeeping);

    approx_downsampled = us_approx;

    for dec_level = decomposition_level:-1:1    
        % upsample this level's coefficients
        detail_coeffs = up_sample(us_details{dec_level});
        approx_coeffs = up_sample(approx_downsampled);

        % apply the filters to hp and lp coeffs
        detail_filtred = apply_filter(detail_coeffs, filter_bank_rec(1,:));
        approx_filtred = apply_filter(approx_coeffs, filter_bank_rec(2,:));

        % select the middle piece of the results with convenient length
        if dec_level == 1
            desired_length = us_bkeeping(end);
        else
            desired_length = us_bkeeping(dec_level-1);
        end
            
        extra_coeffs = length(approx_filtred) - desired_length;
        start_index = floor(extra_coeffs/2) + 1;
        if mod(extra_coeffs,2) == 0
            start_index = start_index - 1;
        end

        % add this level's approx and detail
        approx_downsampled = ...
            detail_filtred(start_index:start_index+desired_length-1) + ...
            approx_filtred(start_index:start_index+desired_length-1);
    end
    
    synthesized_signal = approx_downsampled;

end