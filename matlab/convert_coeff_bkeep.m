function s_bkeeping = convert_coeff_bkeep(us_bkeeping)
    coeff_bkeep_data = us_bkeeping(1:end-1);
    coeff_bkeep_data = flip(coeff_bkeep_data, 2);
    s_bkeeping = [coeff_bkeep_data us_bkeeping(end)];
end

