/* =========================================================================
   tools-map — language toggle
   Flips #page between English (mode-en / LTR) and Arabic (mode-ar / RTL).
   The CSS in styles.css does the actual show/hide + direction; this script
   only swaps the classes and keeps <html lang> and the button label in sync.
   ========================================================================= */
(function () {
  var page = document.getElementById('page');
  var btn = document.getElementById('langToggle');

  function setLang(lang) {
    var isArabic = lang === 'ar';
    page.classList.toggle('mode-ar', isArabic);
    page.classList.toggle('mode-en', !isArabic);
    document.documentElement.lang = lang;
    btn.setAttribute('aria-label', isArabic ? 'التبديل إلى الإنجليزية' : 'Switch to Arabic');
  }

  btn.addEventListener('click', function () {
    setLang(page.classList.contains('mode-ar') ? 'en' : 'ar');
  });
})();
