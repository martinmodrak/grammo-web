Here's a short valid program:

```
data {
  df = {y = numeric, x1 = numeric, group = factor}
}
normal(y, sigma, mu = ~x1)    
```

Now a short invalid program

```
aaa
```

