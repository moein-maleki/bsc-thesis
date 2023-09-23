function s_dwt_coeffs = convert_coeff_ds(us_dwt_coeffs, us_bkeeping)
    decomposition_level = length(us_bkeeping) - 2;
    s_dwt_coeffs = [];
    
    for dec_level = decomposition_level+1:-1:1
        s_dwt_coeffs = [s_dwt_coeffs, us_dwt_coeffs(dec_level, 1:us_bkeeping(dec_level))];
    end
    
end

