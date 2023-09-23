function [image_coeffs, image_bkeeping] = dwt_2d_analysis(input_image, filter_bank_dec, decomposition_level)

[rows, cols] = size(input_image);
image_coeffs = cell(1, decomposition_level+1);
image_bkeeping = zeros(decomposition_level+1, 2);

for dec_level = 1:decomposition_level
    image_coeffs{dec_level} = cell(1, 3);

    cols = floor((cols + length(filter_bank_dec) - 1)/2);
    
    % perform the first stage - on rows
    image_row_detail = zeros(rows, cols);
    image_row_approx = zeros(rows, cols);
    for row_i = 1:rows
        row = input_image(row_i,:);
        [us_row_coeffs, us_row_bkeeping] = dwt_1d_analysis(row, filter_bank_dec, 1);

        image_row_detail(row_i,:) = us_row_coeffs(1, 1:us_row_bkeeping(1));
        image_row_approx(row_i,:) = us_row_coeffs(2, 1:us_row_bkeeping(2));
    end

    rows = floor((rows + length(filter_bank_dec) - 1)/2);
    
    % perform the second stage 
    image_row_detail_col_detail = zeros(rows, cols);
    image_row_detail_col_approx = zeros(rows, cols);
    for col_i = 1:cols
        col = image_row_detail(:,col_i);
        [us_col_coeffs, us_col_bkeeping] = dwt_1d_analysis(col', filter_bank_dec, 1);

        image_row_detail_col_detail(:,col_i) = us_col_coeffs(1, 1:us_col_bkeeping(1))';
        image_row_detail_col_approx(:,col_i) = us_col_coeffs(2, 1:us_col_bkeeping(2))';
    end % on columns and row details
    
    image_row_approx_col_detail = zeros(rows, cols);
    image_row_approx_col_approx = zeros(rows, cols);
    for col_i = 1:cols
        col = image_row_approx(:,col_i);
        [us_col_coeffs, us_col_bkeeping] = dwt_1d_analysis(col', filter_bank_dec, 1);

        image_row_approx_col_detail(:,col_i) = us_col_coeffs(1, 1:us_col_bkeeping(1))';
        image_row_approx_col_approx(:,col_i) = us_col_coeffs(2, 1:us_col_bkeeping(2))';
    end % on columns and row approximations

    % store the three new images - 
    image_coeffs{dec_level}{1} = image_row_detail_col_approx;
    image_coeffs{dec_level}{2} = image_row_detail_col_detail;
    image_coeffs{dec_level}{3} = image_row_approx_col_detail;

    % store the new numbers of cols and rows
    image_bkeeping(dec_level, 1) = rows;
    image_bkeeping(dec_level, 2) = cols;

    % next decomposition level should be applied on approx/approx
    input_image = image_row_approx_col_approx;
end
image_coeffs{decomposition_level+1} = image_row_approx_col_approx;

end

