function details = extract_details(us_coeffs, us_bkeeping)
    decomposition_level = length(us_bkeeping) - 2;
    details = cell(1,decomposition_level);
    
    for dec_level = 1:decomposition_level
        details{dec_level} = us_coeffs(dec_level, 1:us_bkeeping(dec_level));
    end
end

