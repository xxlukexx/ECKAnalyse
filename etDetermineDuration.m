function dur = etDetermineDuration(timeBuffer)

    delta = timeBuffer(2:end, 1) - timeBuffer(1:end - 1, 1);
    md = mode(delta);
    jump = delta > mode(delta) * 10;
    if any(jump)
        delta(jump) = md;
    end
    dur = sum(delta) / 1e6;

end