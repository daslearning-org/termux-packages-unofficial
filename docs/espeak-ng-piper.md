# Custom espeak-ng build
[Piper-TTS](https://github.com/OHF-Voice/piper1-gpl/tree/main) has a dependency with [https://github.com/espeak-ng/espeak-ng/blob/a4ca101c99de35345f89df58195b2159748b7092/src/include/espeak-ng/speak_lib.h#L4], so we are building custom eseapk-ng which will be required by piper.

## Build

### espeak-ng libraries
```bash
rm -rf $TERMUX_PREFIX/lib/libespeak-ng.*
rm -rf $TERMUX_PREFIX/include/espeak-ng
rm -rf $TERMUX_PREFIX/share/espeak-ng-data
rm -rf ~/termux-build/espeakng
rm /data/data/.built-packages/espeakng

mkdir -p /data/data/com.termux/files/usr/include/espeak-ng/
./build-package.sh -a aarch64 -I espeakng 2>&1 | tee logs/espeak-ng2.txt
```

### Piper espeakbridge
```bash
rm -rf $TERMUX_PKG_SRCDIR/espeakbridge.o $TERMUX_PKG_SRCDIR/espeakbridge.so $TERMUX_PKG_SRCDIR/linker_errors.log
rm -rf $TERMUX_PREFIX/lib/python3.11/site-packages/piper
rm -rf $HOME/.termux-build/espeakbridge/
rm /data/data/.built-packages/espeakbridge

./build-package.sh -a aarch64 -I espeakbridge 2>&1 | tee logs/espeak-bridge2.txt
```

---

## Troubleshoot

### espeak-ng

- Issue: espeak_TextToPhonemesWithTerminator is required by `piper-tts` which needs to be built
```bash
ls -l $TERMUX_PREFIX/lib/libespeak-ng.a
ls -l $TERMUX_PREFIX/include/espeak-ng/speak_lib.h
nm $TERMUX_PREFIX/lib/libespeak-ng.a | grep espeak_TextToPhonemesWithTerminator
file $TERMUX_PREFIX/lib/libespeak-ng.a
ls -l $TERMUX_PREFIX/share/espeak-ng-data
```

### espeakbridge for piper

- Verify: `espeakbridge.so` for piper module
```bash
ls -lah $TERMUX_PREFIX/lib/python3.11/site-packages/piper/espeakbridge.so
file $TERMUX_PREFIX/lib/python3.11/site-packages/piper/espeakbridge.so
readelf -d $TERMUX_PREFIX/lib/python3.11/site-packages/piper/espeakbridge.so | grep NEEDED
nm -D $TERMUX_PREFIX/lib/python3.11/site-packages/piper/espeakbridge.so | grep espeak_TextToPhonemesWithTerminator
nm -D $TERMUX_PREFIX/lib/python3.11/site-packages/piper/espeakbridge.so | grep stderr
```
