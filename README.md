# srvk-eesen-offline-transcriber

srvk/eesen customized version of Tanel Alumae's [kaldi-offline-transcriber](https://github.com/alumae/kaldi-offline-transcriber)

You probably want to use this inside the SRVK's [Eesen Transcriber](https://github.com/srvk/eesen-transcriber), not on its own.

### Files in this folder
 * `speech2text.sh` - Transcribe audio/video file and produce several output formats at once (plaintext, subtitles, NIST CTM scoring input, Audacity labels)
 * `vids2web.sh` - Transcribe and create video subtitles and searchable index in a web page
 * `run-segmented.sh` - If you have your own segmentation file this may improve transcription accuracy
 * `run-scored.sh` - If you have STM ground truth as well as audio/video, produce NIST SCLITE scoring results in `build/trans/<videoname>/eesen/decode/score_*`
 * `run-scored-8k.sh` - Same but for 8khz audio such as Switchboard corpus
 * `batch.sh` - Queue several files for transcription
 * `slurm.sh` - for batch processing, edit to change which transcribe script is used (speech2text.sh by default)
 * `mkpages.sh` - Make/update web pages from video and transcription output
 * `watch.sh` - Run this to start watching a shared folder for files to be transcribed
 * `path.sh` - set up the PATH environment variable for the above
 * `Makefile` - master control for transcriber
