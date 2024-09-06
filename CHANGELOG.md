# amfio Change Log

## 1.0.3 (????-??-??)

- Fix exception when a class alias isn't registered, and fall back to anonymous structure, which is what Flash does.

## 1.0.2 (2024-03-13)

- Catch `Dynamic` instead of `openfl.errors.Error` in try/catch to avoid missing other exceptions.

## 1.0.1 (2022-10-11)

- Fix `AMFDictionary` incorrectly comparing `1 == true` for get and set on hxcpp targets.

## 1.0.0 (2022-09-06)

- Initial release
