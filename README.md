# SubtitleAligner
Subtitle Aligner is a bunch of Perl scripts to build a parallel bilingual corpus from .srt subtitles of famous tv series.

It was tested on Windows, but should be fine on other platforms that support perl.

## Converting subtitles
Aligning scripts expect files to be in *.srt format, so you might probably need to convert some of them prior.
To convert files in *.ASS format call:
```
  perl subtitle_ASS_2_SRT.pl input_file.ass >output_file.srt
```
  
## Moving timestamps
If you have found out that some file needs time tuning, you can call:
```
  perl move_subs.pl input_file.srt 5 >output_file.srt
```
where 5 stands for +5 seconds.

## Subtitle aligning
There is a simple subtitle aligner for the files that work for the exact same video. call it with:
```
  perl simple_subtitle_aligner.pl input_file1.srt input_file2.srt output_prefix
```
It will <i>append</i> to corpus files output_prefix.ru and output.ab. so if you want to redo extraction, please delete 
corpus files before running the script.
Sometimes subtitles correspond to differently trimmed videos (probably, due to ads). To detect this issue you can run
analiser by calling:
```
  perl subtitle_pause_search.pl subtitle.srt 5
```
where 5 is a threshold for long pauses. By comparing the results from 2 files you can say if pauses correspond to each other.
If you have this issue, you can try out a smarter aligner, which adjusts to long pauses:
```
  perl aligner_with_pauses.pl input_file1.srt input_file2.srt output_prefix
```
Aligner will <i>append</i> to corpus files output_prefix.ru and output.ab. so if you want to redo extraction, please delete 
corpus files before running the script. 
For batch align make a directory of the following structure:
```
<series_dir>/
  season1/
    ara/
      contentlist
      <file_1>
      <file_2>
      ...
    ru/
      contentlist
      <file_1>
      <file_2>
      ...
  season2/
    ...
```
Each line of "contentlist" file list file you want to align. Make sure that "contentlist" files of directories "ru" and "ara" 
are parallel. Script starts at season1 and finishes when file "season\<NUM\>/ara/contentlist" do not exist. Therefore, contentlists 
should be empty if you don't have files in season. After preparing files run:
```
  perl subtitle_series_aligner.pl <series_dir>
```
The script will create files <series_dir>.ru and <series_dir>.ab respectively.

## Text Extraction
If you want to collect text of only one language (i.g. for n-gram modeling), you can run:
```
  perl SRT_text_extractor.pl input_file.srt >output_file.srt
```
or for batch (assuming that structure is the same as above):
```
  perl SRT_one_lang_extractor <series_dir> <lang>
```
It will create a file <series_dir>.<lang>.txt

## Aligning UN texts
There is an example script, that build a corpus from russian and arabic transcripts of UN documents (conf-dts1.unog.ch).
Call example:
```
  perl UN_extract_RU_ARA_one_pair.pl <arabic_file> <russian_file> <output_prefix>
```
or for batch extraction:
```
  perl UN_extract_RU_ARA.pl <directory>
```
Both scripts will create 2 corpus files: *.ru and *.ab
Directory of batch extraction should contain target files a file "contentlist", that lists filenames to align. Each time 
the script reads two lines of this file and alignes the files mentioned. Each file containing "BT_RUS" in name is considered 
to be russian.
<b>Note</b> that if you extract with *one_pair.pl, the result would be appended to the target files, so if you want to redo 
extraction, please delete result files before running the script.
