/// Phone numbers are stored and transmitted as bare local digits — no country
/// code anywhere, in the UI or in what's sent to the API. [toStoredPhone] just
/// strips incidental whitespace from typed input; [displayPhone] is a no-op
/// today but stays as the one seam every screen already calls, so if this ever
/// needs to change again it changes in one place instead of a dozen.
library;

String toStoredPhone(String typed) => typed.replaceAll(RegExp(r'\s+'), '').trim();

String displayPhone(String? phone) => phone ?? '';
