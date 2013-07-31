#include <stdio.h>
#include <stdlib.h>
#include <string.h>


enum FormatType { Str, Var };

struct Format {
  enum FormatType type;
  const struct Format *next;
  union {
    const char *str;
    int idx;
  };
};

static inline int isdelimiter(char ch);
static inline int flvlen(const char *FORMULAV);
static const char **flvsep(const char *FORMULAV);
static const struct Format *fmtparse(int formulavlen, const char **formulav, const char *FORMAT);
static const struct Format *fmlparse(int formulavlen, const char **formulav, int formulac, const char **FORMULA);

/* ================================================================================
 *   Main program
 * ================================================================================ */

#define STATIC_BUFFER_YSIZE 256
#define STATIC_BUFFER_XSIZE 2048

static char static_buffer[STATIC_BUFFER_YSIZE][STATIC_BUFFER_XSIZE];
static char static_buffered[STATIC_BUFFER_YSIZE];

static int BUFSIZE;
static char **buffer;
static char *buffered;
static char **variables;
static int BUFTOP = 0;
static int bufptr = 0;

static inline void incr_BUFTOP() {
  if (BUFTOP + 1 < BUFSIZE)
    ++BUFTOP;
  else
    BUFTOP = 0;
}

static inline void incr_bufptr() {
  if (bufptr + 1 < BUFSIZE)
    ++bufptr;
  else
    bufptr = 0;
}

static inline void finish_line () {
  if ( ! buffered[BUFTOP] )
    return;

  buffer[BUFTOP][0] = '\0';
  buffered[BUFTOP] = 0;

  incr_BUFTOP();
}

static inline void retry() {
  if ( ! buffered[BUFTOP] )
    return;

  printf ( "%s\n", buffer[BUFTOP] );
  finish_line();
  bufptr = BUFTOP;
}

static inline void finish_finally() {
  bufptr = 0;
  BUFTOP = 0;
}

static inline void finish_failure() {
  for (int j = 0; j < BUFSIZE; ++j)
    retry();

  finish_finally();
}

static inline void finish_success(const struct Format *format) {
  while (format) {
    if (format->type == Str) {
      printf ("%s", format->str);
    } else if (format->type == Var && variables[format->idx]) {
      printf ("%s", variables[format->idx]);
    }

    format = format->next;
  }

  putchar ('\n');

  for (int j = 0; j < BUFSIZE; ++j)
    finish_line();

  finish_finally();
}

int main(int argc, char const *argv[])
{
  const char *FORMULAV = getenv("FORMULAV");

  if ( argc <= 1 ||  FORMULAV == 0 )
    return 1;

  const char *FORMAT   = argv[1];
  const char **FORMULA = argv + 2;

  BUFSIZE   = argc - 2;
  buffer    = calloc(sizeof(char *), BUFSIZE);
  buffered  = calloc(sizeof(char), BUFSIZE);
  variables = calloc(sizeof(char *), BUFSIZE);

  const int formulavlen = flvlen(FORMULAV);
  const char **formulav = flvsep(FORMULAV);

  const struct Format *format = fmtparse(formulavlen, formulav, FORMAT);
  const struct Format *formula = fmlparse(formulavlen, formulav, BUFSIZE, FORMULA);
  const struct Format *fml = formula;

  static char *line;
  static size_t len;

  while (1) {

    if (! fml) {
      fml = formula;
      finish_success(format);
      continue;
    }

    if ( ! buffered[bufptr] ) {

      if ( getline( &line, &len, stdin ) == -1 ) {
        finish_failure();
        return 0;
      } else {

        int x = 0; /* Index of '\n' */
        while ( line[x] && line[x] != '\n' )
          ++x;

        /* If the line does not contains '\n',
         * that is a last line of input and
         * a next input will be EOF always. */
        if (line[x] != '\n') {
          finish_failure();
          printf ("%s", line);
          return 0;
        }

        char *buf;

        if ( bufptr < STATIC_BUFFER_YSIZE && x + 1 < STATIC_BUFFER_XSIZE ) {
          if ( ! static_buffered[bufptr] )
            /* If buffer[y] is heap, I must free the heap. */
            free ( buffer[bufptr] );
            /* If buffer[y] is stack, I should fill up the buffer with 0
              * but I don't, because now I'm no need. */

          buf = static_buffer[bufptr];
          static_buffered[bufptr] = 1;
        } else {
          if ( static_buffered[bufptr] )
            /* If buffer[y] is stack, I can't use realloc() but I need to allocate a new heap. */
            buf = malloc(sizeof(char) * (x + 1));
          else
            /* If buffer[y] is heap, I reallocate the heap by realloc(). */
            buf = realloc(buffer[bufptr], sizeof(char) * (x + 1));

          static_buffered[bufptr] = 0;
        }

        memcpy( buf, line, x );
        buf[x] = '\0';
        buffer[bufptr] = buf;
        buffered[bufptr] = 1;
      }
    }

    if ( fml->type == Str ) {
      if ( strcmp(buffer[bufptr], fml->str) ) {
        fml = formula;
        retry();
        continue;
      }
    } else if ( fml->type == Var )
      variables[fml->idx] = buffer[bufptr];

    fml = fml->next;
    incr_bufptr();
  }

  return 0;
}


/* ================================================================================
 *   Functions for Environmental variable `FORMULAV'.
 * ================================================================================ */


/* --------------------------------------------------------------------------------
 * Decides whether or not it is an allowed character as a delimiter
 * in Environmental variable `FORMULAV'.
 * -------------------------------------------------------------------------------- */
static inline int isdelimiter(char ch) {
  return ch == ' ' || ch == '\n' || ch == '\t' || ch == '\0';
}

/* --------------------------------------------------------------------------------
 * Counts Environmental variable `FORMULAV'.
 * -------------------------------------------------------------------------------- */
static inline int flvlen(const char *FORMULAV)
{
  int r = 0;
  int i = 0;

  while ( FORMULAV[i] )
  {
    if ( ! isdelimiter(FORMULAV[i]) ) {
      ++r;
      do { ++i; } while ( FORMULAV[i] && ! isdelimiter(FORMULAV[i]) );
    } else {
      do { ++i; } while ( FORMULAV[i] && isdelimiter(FORMULAV[i]) );
    }
  }

  return r;
}

/* --------------------------------------------------------------------------------
 * Separates Environmental variable `FORMULAV'.
 * -------------------------------------------------------------------------------- */

static const char **flvsep(const char *FORMULAV)
{
  char **ret = malloc(sizeof(char *) * flvlen(FORMULAV));
  int k = 0;

  for ( int i = 0; FORMULAV[i]; ++i )
  {
    if ( ! isdelimiter(FORMULAV[i]) ) {
      int j = i;
      do { ++j; } while ( FORMULAV[j] && ! isdelimiter(FORMULAV[j]) );
      int len0 = j - i + 1; /* length of string containing '\0' character. */
      int len  = j - i;     /* length of string excluding '\0' character. */

      ret[k] = malloc(sizeof(char) * len0);
      memcpy(ret[k], FORMULAV + i, len);
      ret[k][len] = '\0';

      i = j;
      k++;
    } else {
      do { ++i; } while ( FORMULAV[i] && isdelimiter(FORMULAV[i]) );
    }

    if ( ! FORMULAV[i] )
      break;
  }

  return (const char **) ret;
}

static inline int flv_index_sub(int formulavlen, const char **formulav, const char *s)
{
  for (int i = 0; i < formulavlen; ++i)
  {
    int flg = 1;

    for (int j = 0; formulav[i][j]; ++j)
    {
      if (s[j] == formulav[i][j])
        continue;
      flg = 0;
      break;
    }

    if (flg) return i;
  }

  return -1;
}

static inline int flv_index(int formulavlen, const char **formulav, const char *s)
{
  for (int i = 0; i < formulavlen; ++i)
  {
    if (strcmp(s, formulav[i]))
      continue;
    return i;
  }

  return -1;
}

/* ================================================================================
 *   Functions for Format string.
 * ================================================================================ */

static const struct Format *fmtparse(int formulavlen, const char **formulav, const char *FORMAT)
{
  struct Format *ret = NULL;
  struct Format *prev = NULL;

  int i = 0;
  int j = 0;

  for (j = 0; FORMAT[j]; ++j)
  {
    int idx = flv_index_sub(formulavlen, formulav, FORMAT + j);
    if ( idx == -1 )
      continue;

    if (j > i) {
      int len0 = j - i + 1; /* length of string containing '\0' character. */
      int len  = j - i;     /* length of string excluding '\0' character. */

      struct Format *fmt = malloc(sizeof(struct Format));
      fmt->type = Str;

      char *s = malloc(len0);
      memcpy(s, FORMAT + i, len);
      s[len] = '\0';

      fmt->str = (const char *) s;

      if ( ! ret )
        ret = fmt;

      if ( prev ) {
        prev->next = (const struct Format *) fmt;
        prev = fmt;
      } else {
        prev = fmt;
      }
    }

    i = j + strlen(formulav[idx]);
    struct Format *fmt = malloc(sizeof(struct Format));
    fmt->type = Var;
    fmt->idx = idx;

    if ( ! ret )
      ret = fmt;

    if ( prev ) {
      prev->next = (const struct Format *) fmt;
      prev = fmt;
    } else {
      prev = fmt;
    }
  }

  if (j > i) {
    int len0 = j - i + 1; /* length of string containing '\0' character. */
    int len  = j - i;     /* length of string excluding '\0' character. */

    struct Format *fmt = malloc(sizeof(struct Format));
    fmt->type = Str;
    char *s = malloc(len0);
    memcpy(s, FORMAT + i, len);
    s[len] = '\0';

    fmt->str = (const char *) s;

    if ( ! ret )
      ret = fmt;

    if ( prev ) {
      prev->next = (const struct Format *) fmt;
      prev = fmt;
    } else {
      prev = fmt;
    }
  }

  return ret;
}

/* ================================================================================
 *   Functions for Formula string.
 * ================================================================================ */


static const struct Format *fmlparse(int formulavlen, const char **formulav, int formulac, const char **FORMULA)
{
  struct Format *ret = NULL;
  struct Format *prev = NULL;

  for (int i = 0; i < formulac; ++i)
  {
    struct Format *fmt = malloc(sizeof(struct Format));

    if ( ! ret )
      ret = fmt;

    if ( prev ) {
      prev->next = (const struct Format *) fmt;
      prev = fmt;
    } else {
      prev = fmt;
    }

    int idx = flv_index(formulavlen, formulav, FORMULA[i]);

    if (idx != -1) {
      fmt->type = Var;
      fmt->idx  = idx;
    } else {
      fmt->type = Str;
      fmt->str  = FORMULA[i];
    }
  }

  return ret;
}