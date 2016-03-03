function c = cm(S)
S_bar = S ./ sqrt( sum(sum(abs(S).^2)) );
c = 1 / sum(sum(abs(S_bar)));
