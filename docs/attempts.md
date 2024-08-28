# Attempts

This file acts as a explanation of other attempts that were made before landing on the method explained in this [file.](reverse_blending.md)

## Least squares

We can use least squares to minimize an equation of the form $Ax = b$.

For more information on least squares see the [following document.](least_squares.md)

To do this we need to adjust our equation into the $Ax = b$ form.

```math
\begin{align*}
K_{a} &= K_{b} + \frac{K_{o} - K_{b}}{\alpha_{a}} \\
K_{a} + (K_{b} - K_{o}) \frac{1}{\alpha_{a}} &= K_{b} \\
\end{align*}
```

This doesn't give us $\alpha_{a}$, but it does give us $\frac{1}{\alpha_{a}}$ so it's easy enough to invert that!

We can then plug in as many samples as we want and solve:

```luau
local function reverse(samples: { [RGBA]: RGBA }): RGBA
	local A = {}
	local b = {}

	for Ko, Kb in samples do
		table.insert(A, { 1, 0, 0, Kb.r - Ko.r })
		table.insert(A, { 0, 1, 0, Kb.g - Ko.g })
		table.insert(A, { 0, 0, 1, Kb.b - Ko.b })

		table.insert(b, { Kb.r })
		table.insert(b, { Kb.g })
		table.insert(b, { Kb.b })
	end

	local x = Matrix.leastSquares(A, b)
	return {
		r = x[1][1],
		g = x[2][1],
		b = x[3][1],
		a = 1 / x[4][1], -- 1 / (1 / alpha) = alpha
	}
end
```

[//]: # (https://stackoverflow.com/questions/78140373/calculate-hex-color-with-transparency-based-on-other-colors/78355721#78355721)

## Constrained least squares

This is a valid approach, but it's over-engineered and more computationally complex than it needs to be.

We first calculate all the $K_{a}$ values and then use them with least squares to pick the best fitting alpha value.

This time the equation we're trying to minimize is the following:

```math
K_{o} - K_{b} = \alpha_{a}(K_{a} - K_{b})
```

The whole method in code is as follows:

```luau
local function reverse(Wo: RGBA, Wb: RGBA, Bo: RGBA, Bb: RGBA): RGBA
	local componentByIndex = { "r", "g", "b" }

	local rgb = {0, 0, 0}
	for i = 1, 3 do
		local c = componentByIndex[i]
		local denominator = Bo[c] - Bb[c] + Wb[c] - Wo[c]
		if denominator ~= 0 then
			rgb[i] = (Wb[c] * Bo[c] - Bb[c] * Wo[c]) / denominator
		end
	end

	local A = {
		{ rgb[1] - Wb.r },
		{ rgb[2] - Wb.g },
		{ rgb[3] - Wb.b },
		{ rgb[1] - Bb.r },
		{ rgb[2] - Bb.g },
		{ rgb[3] - Bb.b },
	}

	local b = {
		{ Wo.r - Wb.r },
		{ Wo.g - Wb.g },
		{ Wo.b - Wb.b },
		{ Bo.r - Bb.r },
		{ Bo.g - Bb.g },
		{ Bo.b - Bb.b },
	}

	local x = Matrix.leastSquares(A, b)
	return {
		r = rgb[1],
		g = rgb[2],
		b = rgb[3],
		a = x[1][1],
	}
end
```