function output_arr = read_bin_content(content, q, LINE_COUNT, LINE_WIDTH)
    line_binary = char();
    output_arr = zeros(1, LINE_COUNT);
    for i = 1:LINE_COUNT
        for c = 1:LINE_WIDTH
            bit_char = content((i-1)*LINE_WIDTH+c);
            line_binary = [line_binary bit_char];
        end
        output_arr(i) = bin2num(q, line_binary);
        line_binary = char();
    end
end

