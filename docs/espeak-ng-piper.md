# Custom espeak-ng build

## Troubleshoot

- Issue: espeak_TextToPhonemesWithTerminator is required by `piper-tts` which needs to be built
```bash
ls -l $TERMUX_PREFIX/lib/libespeak-ng.a
ls -l $TERMUX_PREFIX/include/espeak-ng/speak_lib.h
nm $TERMUX_PREFIX/lib/libespeak-ng.a | grep espeak_TextToPhonemesWithTerminator
file $TERMUX_PREFIX/lib/libespeak-ng.a
ls -l $TERMUX_PREFIX/share/espeak-ng-data
```

- Verify: `espeakbridge.so` for piper module
```bash
ls -lah $TERMUX_PREFIX/lib/python3.11/site-packages/piper/espeakbridge.so
file $TERMUX_PREFIX/lib/python3.11/site-packages/piper/espeakbridge.so
readelf -d $TERMUX_PREFIX/lib/python3.11/site-packages/piper/espeakbridge.so | grep NEEDED
nm -D $TERMUX_PREFIX/lib/python3.11/site-packages/piper/espeakbridge.so | grep espeak_TextToPhonemesWithTerminator
nm -D $TERMUX_PREFIX/lib/python3.11/site-packages/piper/espeakbridge.so | grep stderr
```
