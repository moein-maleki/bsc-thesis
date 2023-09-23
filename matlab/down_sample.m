function dissipated_vector = down_sample(original_vector)

    input_signal_length = 2*floor(numel(original_vector)/2);
    dissipated_vector = zeros(1, input_signal_length/2);
    
    for i = 1:input_signal_length
        if mod(i, 2) == 0
            dissipated_vector(i/2) = original_vector(i);
        end
    end
    
end

