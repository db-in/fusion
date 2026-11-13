# Fusion Benchmark History

Every run appends below. Compare across runs in [report.html](report.html).

## 2.1.1-M4Pro

Seeded baseline (Apple M4 Pro). Full table: [Baselines/2.1.1-M4Pro.md](Baselines/2.1.1-M4Pro.md).

| Platform | Suite | Test | Time/op (ns) | Instructions/op | Peak (kB) |
|---|---|---|---:|---:|---:|
| macOS | CorePerformanceTests | testAnyCodableKeyPathMap | 7494 | 141972 | 11040 |
| macOS | CorePerformanceTests | testBase64Encode | 73 | 3352 | 13213 |
| macOS | CorePerformanceTests | testContainsCharacters | 461 | 12927 | 13272 |
| macOS | CorePerformanceTests | testEaseCalculate | 6 | 1670 | 13288 |
| macOS | CorePerformanceTests | testFilteredByTextOf1000 | 4397196 | 85713944 | 13370 |
| macOS | CorePerformanceTests | testFlushPendingWritesWhenIdle | 134 | 6165 | 13452 |
| macOS | CorePerformanceTests | testFlushPendingWritesWith50TrackedFileKeys | 11494000 | 128454311 | 13757 |
| macOS | CorePerformanceTests | testHMACSHA256 | 18855 | 437181 | 13862 |
| macOS | CorePerformanceTests | testInMemoryCacheGetOrSet | 74 | 3355 | 13878 |
| macOS | CorePerformanceTests | testJSONDecode | 53229 | 921293 | 14284 |
| macOS | CorePerformanceTests | testJSONDecodeArrayOf500 | 31852140 | 453684903 | 15644 |
| macOS | CorePerformanceTests | testJSONEncode | 3143 | 60130 | 15526 |
| macOS | CorePerformanceTests | testKeychainWriteAndRead | 5075138 | 36338011 | 21634 |
| macOS | CorePerformanceTests | testRegexReplacing | 1840 | 44063 | 16965 |
| macOS | CorePerformanceTests | testSendToTenSubscribers | 3256 | 76243 | 37333 |
| macOS | CorePerformanceTests | testSHA256OfOneKilobyte | 594 | 7395 | 40142 |
| macOS | CorePerformanceTests | testStateStorageSetAndRead | 2872 | 54912 | 40158 |
| macOS | CorePerformanceTests | testThreadSafeMutate | 7 | 1716 | 40174 |
| macOS | CorePerformanceTests | testThreadSafeRead | 6 | 1694 | 40174 |
| macOS | CorePerformanceTests | testUniqueOf1000 | 41466 | 1055213 | 40174 |
| macOS | HotPathPerformanceTests | testAbsentKeyReads | 2945 | 52825 | 40174 |
| macOS | HotPathPerformanceTests | testAppGroupURL | 45 | 2670 | 40174 |
| macOS | HotPathPerformanceTests | testColorHex | 597 | 14831 | 40224 |
| macOS | HotPathPerformanceTests | testConvertedDigitsToLocale | 32157 | 438737 | 40568 |
| macOS | HotPathPerformanceTests | testDateToStringWithFormat | 1213 | 28173 | 40666 |
| macOS | HotPathPerformanceTests | testFileStorageWrites | 3249 | 95597 | 40853 |
| macOS | HotPathPerformanceTests | testLocalized | 886 | 18810 | 48720 |
| macOS | HotPathPerformanceTests | testNumberToString | 672 | 14996 | 48812 |
| macOS | HotPathPerformanceTests | testPreferredLocale | 828 | 18043 | 48809 |
| macOS | HotPathPerformanceTests | testPresentKeyColdReads | 16692 | 239410 | 50513 |
| macOS | HotPathPerformanceTests | testSilentLoggerWithoutSaving | 5 | 1722 | 50513 |
| macOS | HotPathPerformanceTests | testTimeUnits | 23165 | 404776 | 50660 |
| macOS | HotPathPerformanceTests | testUTCDateFormatting | 1002 | 23242 | 50660 |
| macOS | HotPathPerformanceTests | testUTCDateParsing | 49984 | 888583 | 50588 |
| iOS | CorePerformanceTests | testAnyCodableKeyPathMap | 8629 | 130159 | 20748 |
| iOS | CorePerformanceTests | testBase64Encode | 66 | 3287 | 21816 |
| iOS | CorePerformanceTests | testContainsCharacters | 448 | 11892 | 21823 |
| iOS | CorePerformanceTests | testEaseCalculate | 8 | 1998 | 21852 |
| iOS | CorePerformanceTests | testFilteredByTextOf1000 | 5269592 | 87023111 | 24365 |
| iOS | CorePerformanceTests | testFlushPendingWritesWhenIdle | 197 | 6458 | 25250 |
| iOS | CorePerformanceTests | testFlushPendingWritesWith50TrackedFileKeys | 16405000 | 148846922 | 25276 |
| iOS | CorePerformanceTests | testHMACSHA256 | 25004 | 383058 | 25299 |
| iOS | CorePerformanceTests | testInMemoryCacheGetOrSet | 73 | 3247 | 25332 |
| iOS | CorePerformanceTests | testJSONDecode | 68433 | 859917 | 25496 |
| iOS | CorePerformanceTests | testJSONDecodeArrayOf500 | 30264590 | 419836943 | 25506 |
| iOS | CorePerformanceTests | testJSONEncode | 2864 | 52329 | 25437 |
| iOS | CorePerformanceTests | testKeychainWriteAndRead | 1155002 | 372126 | 25450 |
| iOS | CorePerformanceTests | testRegexReplacing | 1684 | 40679 | 25548 |
| iOS | CorePerformanceTests | testSendToTenSubscribers | 3408 | 65788 | 45750 |
| iOS | CorePerformanceTests | testSHA256OfOneKilobyte | 583 | 7379 | 25761 |
| iOS | CorePerformanceTests | testStateStorageSetAndRead | 2820 | 53468 | 25758 |
| iOS | CorePerformanceTests | testThreadSafeMutate | 6 | 1912 | 25758 |
| iOS | CorePerformanceTests | testThreadSafeRead | 6 | 1751 | 25758 |
| iOS | CorePerformanceTests | testUniqueOf1000 | 32234 | 734458 | 25778 |
| iOS | HotPathPerformanceTests | testAbsentKeyReads | 8592 | 133125 | 25771 |
| iOS | HotPathPerformanceTests | testAppGroupURL | 41 | 2470 | 25791 |
| iOS | HotPathPerformanceTests | testColorHex | 640 | 13476 | 25801 |
| iOS | HotPathPerformanceTests | testConvertedDigitsToLocale | 30348 | 371621 | 25876 |
| iOS | HotPathPerformanceTests | testDateToStringWithFormat | 1363 | 25609 | 25922 |
| iOS | HotPathPerformanceTests | testFileStorageWrites | 3412 | 60685 | 25886 |
| iOS | HotPathPerformanceTests | testLocalized | 1106 | 22621 | 30323 |
| iOS | HotPathPerformanceTests | testNumberToString | 622 | 13404 | 30313 |
| iOS | HotPathPerformanceTests | testPreferredLocale | 1090 | 21821 | 30313 |
| iOS | HotPathPerformanceTests | testPresentKeyColdReads | 38495 | 440359 | 30539 |
| iOS | HotPathPerformanceTests | testSilentLoggerWithoutSaving | 6 | 1810 | 30608 |
| iOS | HotPathPerformanceTests | testTimeUnits | 23380 | 368894 | 30981 |
| iOS | HotPathPerformanceTests | testUTCDateFormatting | 905 | 21580 | 31319 |
| iOS | HotPathPerformanceTests | testUTCDateParsing | 64405 | 833184 | 31702 |
| iOS | ImagePipelinePerformanceTests | testCorruptCachedImageLoad | 20491 | 251162 | 32793 |
| iOS | ImagePipelinePerformanceTests | testDecodeDownsampled1024To128 | 2794540 | 66480495 | 40396 |
| iOS | ImagePipelinePerformanceTests | testDecodeFullSize1024 | 1422260 | 26040646 | 121621 |
| iOS | ImagePipelinePerformanceTests | testFlushCacheWith20Images | 22800 | 3692971 | 33468 |
| iOS | ImagePipelinePerformanceTests | testMemoryCacheHit | 104 | 3643 | 33524 |
| iOS | ImagePipelinePerformanceTests | testMemoryCacheMiss | 142 | 6260 | 33524 |
| iOS | ImagePipelinePerformanceTests | testURLCacheAppGroupAccess | 1148 | 26192 | 33524 |
| iOS | ImagePipelinePerformanceTests | testURLCacheLoadAndDecode | 323993 | 4144711 | 37020 |
| iOS | UIPerformanceTests | testColorDarker | 273 | 7354 | 35107 |
| iOS | UIPerformanceTests | testColorInterpolation | 5604 | 112517 | 35153 |
| iOS | UIPerformanceTests | testResizedImage128To64 | 112650 | 2184604 | 41942 |
| iOS | UIPerformanceTests | testSizeThatFits | 17796 | 301628 | 35251 |
| iOS | UIPerformanceTests | testSolidImage32 | 10688 | 131400 | 35261 |
| iOS | UIPerformanceTests | testStyledText | 1373 | 29882 | 35244 |
| iOS | UIPerformanceTests | testTextBoundingSize | 14914 | 242496 | 35333 |
| iOS | UIPerformanceTests | testTintedImage128 | 627485 | 16294123 | 42755 |

## 20261113-134239-2b21b5f-dirty

```
date: 2026-11-13T09:42:39Z
commit: 2b21b5fa682a9f6b0ea92ac0a1cd57b69cc8b9e9
branch: master
dirty: yes
model: Mac16,8
cpu: Apple M4 Pro
cores: 12 physical, 12 logical
memory_gb: 24
macos: 27.0.1 (26A434)
xcode: Xcode 27.2 Build version 27B52 
swift: Apple Swift version 6.4.2 (swiftlang-6.4.2.1.9 clang-2100.4.1.1)
power: Now drawing from 'AC Power'
thermal: Note: No thermal warning level has been recorded Note: No performance warning level has been recorded Note: No CPU power status has been recorded 
ios_device: iPhone 17 latest
runner: xcode
```

| Platform | Suite | Test | Time/op (ns) | Instructions/op | Peak (kB) |
|---|---|---|---:|---:|---:|
| macOS | CorePerformanceTests | testAnyCodableKeyPathMap | 8198 | 139686 | 10726 |
| macOS | CorePerformanceTests | testBase64Encode | 68 | 3295 | 38831 |
| macOS | CorePerformanceTests | testContainsCharacters | 510 | 12349 | 38923 |
| macOS | CorePerformanceTests | testEaseCalculate | 6 | 1669 | 38933 |
| macOS | CorePerformanceTests | testFilteredByTextOf1000 | 4946648 | 82248363 | 39044 |
| macOS | CorePerformanceTests | testFlushPendingWritesWhenIdle | 133 | 5971 | 32113 |
| macOS | CorePerformanceTests | testFlushPendingWritesWith50TrackedFileKeys | 12109600 | 130946073 | 32412 |
| macOS | CorePerformanceTests | testHMACSHA256 | 19089 | 405266 | 32589 |
| macOS | CorePerformanceTests | testInMemoryCacheGetOrSet | 82 | 3380 | 32621 |
| macOS | CorePerformanceTests | testJSONDecode | 58027 | 874922 | 32962 |
| macOS | CorePerformanceTests | testJSONDecodeArrayOf500 | 25636080 | 429440642 | 18410 |
| macOS | CorePerformanceTests | testJSONEncode | 3087 | 59036 | 18407 |
| macOS | CorePerformanceTests | testKeychainWriteAndRead | 13277404 | 63988178 | 23912 |
| macOS | CorePerformanceTests | testRegexReplacing | 1744 | 42598 | 22244 |
| macOS | CorePerformanceTests | testSendToTenSubscribers | 2986 | 73701 | 42445 |
| macOS | CorePerformanceTests | testSHA256OfOneKilobyte | 576 | 7153 | 52790 |
| macOS | CorePerformanceTests | testStateStorageSetAndRead | 2770 | 52938 | 52823 |
| macOS | CorePerformanceTests | testThreadSafeMutate | 6 | 1720 | 52872 |
| macOS | CorePerformanceTests | testThreadSafeRead | 12 | 1688 | 52872 |
| macOS | CorePerformanceTests | testUniqueOf1000 | 103996 | 2402440 | 52872 |
| macOS | HotPathPerformanceTests | testAbsentKeyReads | 3080 | 51821 | 52872 |
| macOS | HotPathPerformanceTests | testAppGroupURL | 52 | 2648 | 52872 |
| macOS | HotPathPerformanceTests | testColorHex | 658 | 13847 | 52921 |
| macOS | HotPathPerformanceTests | testConvertedDigitsToLocale | 34644 | 413355 | 55677 |
| macOS | HotPathPerformanceTests | testDateToStringWithFormat | 1317 | 28077 | 55821 |
| macOS | HotPathPerformanceTests | testFileStorageWrites | 4883 | 81933 | 55867 |
| macOS | HotPathPerformanceTests | testLocalized | 1214 | 18517 | 26586 |
| macOS | HotPathPerformanceTests | testNumberToString | 895 | 14744 | 26674 |
| macOS | HotPathPerformanceTests | testPreferredLocale | 1099 | 17731 | 26674 |
| macOS | HotPathPerformanceTests | testPresentKeyColdReads | 26004 | 250465 | 28591 |
| macOS | HotPathPerformanceTests | testSilentLoggerWithoutSaving | 12 | 1715 | 28591 |
| macOS | HotPathPerformanceTests | testTimeUnits | 28314 | 400287 | 28722 |
| macOS | HotPathPerformanceTests | testUTCDateFormatting | 1094 | 23055 | 28742 |
| macOS | HotPathPerformanceTests | testUTCDateParsing | 69708 | 844727 | 28820 |
| iOS | CorePerformanceTests | testAnyCodableKeyPathMap | 10532 | 132509 | 22652 |
| iOS | CorePerformanceTests | testBase64Encode | 84 | 3217 | 23808 |
| iOS | CorePerformanceTests | testContainsCharacters | 508 | 12147 | 23808 |
| iOS | CorePerformanceTests | testEaseCalculate | 10 | 1916 | 23825 |
| iOS | CorePerformanceTests | testFilteredByTextOf1000 | 5955880 | 86618195 | 24949 |
| iOS | CorePerformanceTests | testFlushPendingWritesWhenIdle | 208 | 6688 | 25031 |
| iOS | CorePerformanceTests | testFlushPendingWritesWith50TrackedFileKeys | 18933800 | 139144710 | 25018 |
| iOS | CorePerformanceTests | testHMACSHA256 | 19292 | 380073 | 25070 |
| iOS | CorePerformanceTests | testInMemoryCacheGetOrSet | 82 | 3276 | 25103 |
| iOS | CorePerformanceTests | testJSONDecode | 73066 | 858772 | 25208 |
| iOS | CorePerformanceTests | testJSONDecodeArrayOf500 | 37796180 | 424030308 | 25706 |
| iOS | CorePerformanceTests | testJSONEncode | 3106 | 52754 | 25293 |
| iOS | CorePerformanceTests | testKeychainWriteAndRead | 2005650 | 764352 | 25286 |
| iOS | CorePerformanceTests | testRegexReplacing | 1758 | 40788 | 25335 |
| iOS | CorePerformanceTests | testSendToTenSubscribers | 3204 | 65624 | 45586 |
| iOS | CorePerformanceTests | testSHA256OfOneKilobyte | 615 | 7075 | 25660 |
| iOS | CorePerformanceTests | testStateStorageSetAndRead | 2857 | 53970 | 25627 |
| iOS | CorePerformanceTests | testThreadSafeMutate | 7 | 1794 | 25627 |
| iOS | CorePerformanceTests | testThreadSafeRead | 7 | 1937 | 25627 |
| iOS | CorePerformanceTests | testUniqueOf1000 | 80261 | 1832046 | 25634 |
| iOS | HotPathPerformanceTests | testAbsentKeyReads | 8066 | 127421 | 25653 |
| iOS | HotPathPerformanceTests | testAppGroupURL | 48 | 2570 | 25647 |
| iOS | HotPathPerformanceTests | testColorHex | 596 | 13297 | 25660 |
| iOS | HotPathPerformanceTests | testConvertedDigitsToLocale | 32037 | 370759 | 25781 |
| iOS | HotPathPerformanceTests | testDateToStringWithFormat | 1333 | 25803 | 25774 |
| iOS | HotPathPerformanceTests | testFileStorageWrites | 4125 | 73887 | 25817 |
| iOS | HotPathPerformanceTests | testLocalized | 1235 | 22677 | 28763 |
| iOS | HotPathPerformanceTests | testNumberToString | 679 | 13431 | 28743 |
| iOS | HotPathPerformanceTests | testPreferredLocale | 1127 | 21911 | 28740 |
| iOS | HotPathPerformanceTests | testPresentKeyColdReads | 54133 | 429034 | 29110 |
| iOS | HotPathPerformanceTests | testSilentLoggerWithoutSaving | 7 | 1800 | 29605 |
| iOS | HotPathPerformanceTests | testTimeUnits | 40850 | 381188 | 30028 |
| iOS | HotPathPerformanceTests | testUTCDateFormatting | 1088 | 21548 | 30133 |
| iOS | HotPathPerformanceTests | testUTCDateParsing | 90271 | 864285 | 31017 |
| iOS | ImagePipelinePerformanceTests | testCorruptCachedImageLoad | 48567 | 350677 | 32839 |
| iOS | ImagePipelinePerformanceTests | testDecodeDownsampled1024To128 | 3639990 | 77007176 | 40510 |
| iOS | ImagePipelinePerformanceTests | testDecodeFullSize1024 | 21687470 | 25646553 | 121795 |
| iOS | ImagePipelinePerformanceTests | testFlushCacheWith20Images | 17800 | 3720664 | 33642 |
| iOS | ImagePipelinePerformanceTests | testMemoryCacheHit | 154 | 3614 | 33511 |
| iOS | ImagePipelinePerformanceTests | testMemoryCacheMiss | 183 | 4343 | 33508 |
| iOS | ImagePipelinePerformanceTests | testURLCacheAppGroupAccess | 1667 | 26646 | 33514 |
| iOS | ImagePipelinePerformanceTests | testURLCacheLoadAndDecode | 5558840 | 2096876 | 37066 |
| iOS | UIPerformanceTests | testColorDarker | 328 | 7396 | 35090 |
| iOS | UIPerformanceTests | testColorInterpolation | 6844 | 112795 | 35166 |
| iOS | UIPerformanceTests | testResizedImage128To64 | 152395 | 2189375 | 41864 |
| iOS | UIPerformanceTests | testSizeThatFits | 26514 | 308609 | 35208 |
| iOS | UIPerformanceTests | testSolidImage32 | 16973 | 129542 | 35251 |
| iOS | UIPerformanceTests | testStyledText | 1954 | 29722 | 35244 |
| iOS | UIPerformanceTests | testTextBoundingSize | 21588 | 244010 | 35228 |
| iOS | UIPerformanceTests | testTintedImage128 | 946951 | 16348850 | 43980 |

## 20261113-135302-2b21b5f-dirty

```
date: 2026-11-13T09:53:03Z
commit: 2b21b5fa682a9f6b0ea92ac0a1cd57b69cc8b9e9
branch: master
dirty: yes
model: Mac16,8
cpu: Apple M4 Pro
cores: 12 physical, 12 logical
memory_gb: 24
macos: 27.0.1 (26A434)
xcode: Xcode 27.2 Build version 27B52 
swift: Apple Swift version 6.4.2 (swiftlang-6.4.2.1.9 clang-2100.4.1.1)
power: Now drawing from 'AC Power'
thermal: Note: No thermal warning level has been recorded Note: No performance warning level has been recorded Note: No CPU power status has been recorded 
ios_device: iPhone 17 latest
runner: xcode
```

| Platform | Suite | Test | Time/op (ns) | Instructions/op | Peak (kB) |
|---|---|---|---:|---:|---:|
| macOS | CorePerformanceTests | testAnyCodableKeyPathMap | 7252 | 139365 | 10677 |
| macOS | CorePerformanceTests | testBase64Encode | 66 | 3272 | 37622 |
| macOS | CorePerformanceTests | testContainsCharacters | 422 | 12270 | 37687 |
| macOS | CorePerformanceTests | testEaseCalculate | 6 | 1674 | 37750 |
| macOS | CorePerformanceTests | testFilteredByTextOf1000 | 4410016 | 82147220 | 37655 |
| macOS | CorePerformanceTests | testFlushPendingWritesWhenIdle | 116 | 5780 | 37422 |
| macOS | CorePerformanceTests | testFlushPendingWritesWith50TrackedFileKeys | 11535600 | 128901278 | 37713 |
| macOS | CorePerformanceTests | testHMACSHA256 | 17705 | 404555 | 37822 |
| macOS | CorePerformanceTests | testInMemoryCacheGetOrSet | 73 | 3337 | 37851 |
| macOS | CorePerformanceTests | testJSONDecode | 54247 | 873025 | 37677 |
| macOS | CorePerformanceTests | testJSONDecodeArrayOf500 | 24455570 | 428903966 | 21510 |
| macOS | CorePerformanceTests | testJSONEncode | 2942 | 59150 | 18253 |
| macOS | CorePerformanceTests | testKeychainWriteAndRead | 12867872 | 65658548 | 22273 |
| macOS | CorePerformanceTests | testRegexReplacing | 1686 | 42535 | 20972 |
| macOS | CorePerformanceTests | testSendToTenSubscribers | 3098 | 73630 | 41118 |
| macOS | CorePerformanceTests | testSHA256OfOneKilobyte | 590 | 7182 | 51414 |
| macOS | CorePerformanceTests | testStateStorageSetAndRead | 2790 | 54083 | 51427 |
| macOS | CorePerformanceTests | testThreadSafeMutate | 6 | 1718 | 51401 |
| macOS | CorePerformanceTests | testThreadSafeRead | 6 | 1723 | 51414 |
| macOS | CorePerformanceTests | testUniqueOf1000 | 96097 | 2388647 | 51430 |
| macOS | HotPathPerformanceTests | testAbsentKeyReads | 3038 | 51806 | 51443 |
| macOS | HotPathPerformanceTests | testAppGroupURL | 42 | 2635 | 51447 |
| macOS | HotPathPerformanceTests | testColorHex | 552 | 13807 | 51496 |
| macOS | HotPathPerformanceTests | testConvertedDigitsToLocale | 31104 | 411819 | 51594 |
| macOS | HotPathPerformanceTests | testDateToStringWithFormat | 1308 | 28065 | 52135 |
| macOS | HotPathPerformanceTests | testFileStorageWrites | 3837 | 88450 | 52263 |
| macOS | HotPathPerformanceTests | testLocalized | 877 | 18396 | 26481 |
| macOS | HotPathPerformanceTests | testNumberToString | 666 | 14613 | 26559 |
| macOS | HotPathPerformanceTests | testPreferredLocale | 832 | 17599 | 26559 |
| macOS | HotPathPerformanceTests | testPresentKeyColdReads | 18739 | 240504 | 28378 |
| macOS | HotPathPerformanceTests | testSilentLoggerWithoutSaving | 5 | 1710 | 28378 |
| macOS | HotPathPerformanceTests | testTimeUnits | 24304 | 398874 | 28558 |
| macOS | HotPathPerformanceTests | testUTCDateFormatting | 951 | 23049 | 28558 |
| macOS | HotPathPerformanceTests | testUTCDateParsing | 50379 | 840676 | 28722 |
| iOS | CorePerformanceTests | testAnyCodableKeyPathMap | 11870 | 133109 | 20407 |
| iOS | CorePerformanceTests | testBase64Encode | 68 | 3185 | 21420 |
| iOS | CorePerformanceTests | testContainsCharacters | 458 | 12071 | 21498 |
| iOS | CorePerformanceTests | testEaseCalculate | 9 | 1934 | 21564 |
| iOS | CorePerformanceTests | testFilteredByTextOf1000 | 6526848 | 86874867 | 24785 |
| iOS | CorePerformanceTests | testFlushPendingWritesWhenIdle | 166 | 6501 | 25040 |
| iOS | CorePerformanceTests | testFlushPendingWritesWith50TrackedFileKeys | 19683600 | 143795796 | 25031 |
| iOS | CorePerformanceTests | testHMACSHA256 | 25873 | 381484 | 25070 |
| iOS | CorePerformanceTests | testInMemoryCacheGetOrSet | 71 | 3514 | 25070 |
| iOS | CorePerformanceTests | testJSONDecode | 74534 | 859743 | 25188 |
| iOS | CorePerformanceTests | testJSONDecodeArrayOf500 | 43881470 | 432354702 | 25656 |
| iOS | CorePerformanceTests | testJSONEncode | 3296 | 53134 | 25250 |
| iOS | CorePerformanceTests | testKeychainWriteAndRead | 2238690 | 937040 | 25276 |
| iOS | CorePerformanceTests | testRegexReplacing | 3043 | 40791 | 25319 |
| iOS | CorePerformanceTests | testSendToTenSubscribers | 3337 | 65711 | 45589 |
| iOS | CorePerformanceTests | testSHA256OfOneKilobyte | 656 | 7011 | 25561 |
| iOS | CorePerformanceTests | testStateStorageSetAndRead | 3459 | 53848 | 25565 |
| iOS | CorePerformanceTests | testThreadSafeMutate | 8 | 1901 | 25561 |
| iOS | CorePerformanceTests | testThreadSafeRead | 6 | 1798 | 25545 |
| iOS | CorePerformanceTests | testUniqueOf1000 | 94517 | 1831499 | 25545 |
| iOS | HotPathPerformanceTests | testAbsentKeyReads | 8742 | 127786 | 25539 |
| iOS | HotPathPerformanceTests | testAppGroupURL | 49 | 2560 | 25545 |
| iOS | HotPathPerformanceTests | testColorHex | 578 | 13510 | 25640 |
| iOS | HotPathPerformanceTests | testConvertedDigitsToLocale | 32874 | 371071 | 25824 |
| iOS | HotPathPerformanceTests | testDateToStringWithFormat | 1370 | 25758 | 25860 |
| iOS | HotPathPerformanceTests | testFileStorageWrites | 4079 | 63099 | 25906 |
| iOS | HotPathPerformanceTests | testLocalized | 1236 | 22846 | 29471 |
| iOS | HotPathPerformanceTests | testNumberToString | 639 | 13427 | 29444 |
| iOS | HotPathPerformanceTests | testPreferredLocale | 1147 | 21866 | 30853 |
| iOS | HotPathPerformanceTests | testPresentKeyColdReads | 35152 | 426679 | 30932 |
| iOS | HotPathPerformanceTests | testSilentLoggerWithoutSaving | 6 | 1773 | 30896 |
| iOS | HotPathPerformanceTests | testTimeUnits | 25974 | 369059 | 30919 |
| iOS | HotPathPerformanceTests | testUTCDateFormatting | 925 | 21592 | 31463 |
| iOS | HotPathPerformanceTests | testUTCDateParsing | 76063 | 842064 | 31683 |
| iOS | ImagePipelinePerformanceTests | testCorruptCachedImageLoad | 17792 | 246734 | 32656 |
| iOS | ImagePipelinePerformanceTests | testDecodeDownsampled1024To128 | 3298780 | 66365984 | 38833 |
| iOS | ImagePipelinePerformanceTests | testDecodeFullSize1024 | 23662400 | 25612289 | 121310 |
| iOS | ImagePipelinePerformanceTests | testFlushCacheWith20Images | 24200 | 4417300 | 33213 |
| iOS | ImagePipelinePerformanceTests | testMemoryCacheHit | 109 | 4401 | 33059 |
| iOS | ImagePipelinePerformanceTests | testMemoryCacheMiss | 139 | 4455 | 33082 |
| iOS | ImagePipelinePerformanceTests | testURLCacheAppGroupAccess | 1310 | 28522 | 33105 |
| iOS | ImagePipelinePerformanceTests | testURLCacheLoadAndDecode | 3478827 | 2089372 | 36670 |
| iOS | UIPerformanceTests | testColorDarker | 277 | 7049 | 34841 |
| iOS | UIPerformanceTests | testColorInterpolation | 5610 | 112390 | 34907 |
| iOS | UIPerformanceTests | testResizedImage128To64 | 113178 | 2178653 | 41582 |
| iOS | UIPerformanceTests | testSizeThatFits | 18131 | 301981 | 34835 |
| iOS | UIPerformanceTests | testSolidImage32 | 10108 | 128775 | 34881 |
| iOS | UIPerformanceTests | testStyledText | 1408 | 29899 | 34851 |
| iOS | UIPerformanceTests | testTextBoundingSize | 14720 | 243290 | 34884 |
| iOS | UIPerformanceTests | testTintedImage128 | 666523 | 16282405 | 42290 |
