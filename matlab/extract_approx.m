function approx = extract_approx(us_coeffs, us_bkeeping)
    decomposition_level = length(us_bkeeping) - 2;
    approx = us_coeffs(decomposition_level+1, 1:us_bkeeping(decomposition_level+1));
end

