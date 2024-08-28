# Least Squares

Suppose that $Ax = b$ does not have a solution. What's the best approximate solution?

We can find some $\hat{x}$ such that for all $\bar{x}$ we have:

```math
|| A\hat{x} - b || \le || A\bar{x} - b ||
```

How do we do this?

Intuitively we know that for all column vectors in $A$ the following must be true because our solution will be orthogonal to the the span of the $A$ matrix.

```math
\begin{align*}
A_{c1} \cdot (A\hat{x} - b) &= 0 \\
A_{c2} \cdot (A\hat{x} - b) &= 0 \\
\cdots \\
A_{cn} \cdot (A\hat{x} - b) &= 0 \\
\end{align*}
```

Writing the dot product as a transpose:

```math
\begin{align*}
A_{c1}^T (A\hat{x} - b) &= 0 \\
A_{c2}^T (A\hat{x} - b) &= 0 \\
\cdots \\
A_{cn}^T (A\hat{x} - b) &= 0 \\
\end{align*}
```

Or as a singular equation we can simply write:

```math
\begin{align*}
A^T(A\hat{x} - b) &= 0 \\
A^TA\hat{x} - A^Tb &= 0 \\
A^TA\hat{x} &= A^Tb
\end{align*}
```

Which can then be rearranged to solve for $\hat{x}$

```math
\hat{x} = (A^T A)^{-1} A^Tb
```