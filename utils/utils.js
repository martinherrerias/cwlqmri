
// return (composed) file extension, e.g. '.nii.gz'
function extension2(file) {
    var match = file.basename.match(/([^.]*)(\.[a-z.]*)$/i);
    return match ? match[2] : '';
}

// return nameroot without (composed) extension
function nameroot2(file) {
    var match = file.basename.match(/([^.]*)(\.[a-z.]*)$/i);
    return match ? match[1] : '';
}