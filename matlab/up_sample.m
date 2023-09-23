function upsampled_vector = up_sample(original_vector)
    input_length = numel(original_vector);
    upsampled_vector = zeros(1, 2*numel(original_vector));
    for i = 0:input_length-1
        upsampled_vector(2*i+1) = original_vector(i+1);
    end
end

