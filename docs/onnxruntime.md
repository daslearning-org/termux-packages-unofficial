# Building Python Onnxruntime

## NDK 25b

### New patches

#### Disable `bfloat16_t` error

1. Update the `mlasi.h` with below code
```cpp
#if !defined(bfloat16_t)
typedef uint16_t bfloat16_t;
#endif
```

2. Generate a patch file
```bash
diff -u mlasi.h mlasi_updated.h > mlas-bfloat16.patch
```

3. Then put the patch file [here](../packages/python-onnxruntime/0006-mlas-bfloat16.patch)
